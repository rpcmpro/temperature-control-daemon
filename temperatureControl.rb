require 'em-http-request'
require 'json'
require 'optparse'

class TemperatureControl
  @@logfile = 'temperatureControl.log'
  @@verbose = false
  @@daemonize = false
  @@workingDirectory = Dir.pwd
  @@loggingToFile = true
  @@version = "0.1.2"

  def self.readConfig

    @@optionsParser = OptionParser.new do |opts|
      opts.banner = "\nTemperature Control Daemon version #{@@version} for RPCM ME (http://rpcm.pro)\n\nUsage: temperatureControl.rb [options]"

      opts.on("-d", "--daemonize", "Daemonize and return control") do |v|
        @@daemonize = v
      end

      opts.on("-l", "--[no-]log", "Save log to file") do |v|
        @@loggingToFile = v
      end

      opts.on("-v", "--verbose", "Run verbosely") do |v|
        @@verbose = v
      end

      opts.on("-w", "--working-directory PATH", "Specify working directory (default current directory)") do |v|
        @@workingDirectory = v
      end
    end

    @@optionsParser.parse!

    configText = File.read "#{@@workingDirectory}/temperatureControl.conf"

    @@configHash = JSON.parse configText

    if @@configHash.class != Hash
      TemperatureControl.log text: "#{Time.now} Error parsing config. Exiting..."
      exit 1
    end
  end

  def self.daemonize
    @@daemonize
  end

  def self.verbose
    @@verbose
  end

  def self.configHash
    @@configHash
  end

  def self.log text:
    puts text

    if @@loggingToFile
      f = File.open "#{@@workingDirectory}/#{@@logfile}", 'a'
      f.puts text
      f.close
    end
  end
end

class TemperatureGetter
  def self.getTemperatureAndOutletsStates forRPCM:
    apiAddress = TemperatureControl.configHash[forRPCM]['api_address']

    http = EventMachine::HttpRequest.new("http://#{apiAddress}:8888/api/cachedStatus").get

    http.errback do
      puts "#{Time.now} Error requesting #{apiAddress}"

      GC.start full_mark: true, immediate_sweep: true
    end
    http.callback do
      jsonHash = JSON.parse http.response

      if jsonHash.class == Hash
        temperature = jsonHash['temp']

        jsonHash['ats']['channels'].each_key do |outlet|
          offTemp = TemperatureControl.configHash[forRPCM]['outlets'][outlet]['offTemp']
          onTemp = TemperatureControl.configHash[forRPCM]['outlets'][outlet]['onTemp']
          admS = jsonHash['ats']['channels'][outlet]['admS']
          iMa = jsonHash['ats']['channels'][outlet]['iMa']

          if TemperatureControl.verbose
            TemperatureControl.log text: "#{Time.now} #{apiAddress} (#{forRPCM}) Outlet #{outlet} state is #{admS} load is #{iMa}mA offTemp #{offTemp} onTemp #{onTemp} currentTemp #{temperature}"
          end
          if (temperature > offTemp) and (admS == 'ON')
            switch apiAddress: apiAddress, outlet: outlet, state: 'off'
          elsif (temperature < onTemp) and (admS == 'OFF')
            switch apiAddress: apiAddress, outlet: outlet, state: 'on'
          end
        end
      end

      GC.start full_mark: true, immediate_sweep: true
    end
  end

  def self.switch apiAddress:, outlet:, state:
    if (state != 'on') and (state != 'off')
      TemperatureControl.log text: "#{Time.now} wrong state requested #{state}"
      return
    end

    TemperatureControl.log text: "#{Time.now} Turning #{apiAddress} outlet #{outlet} #{state}"

    turnOffHttpRequest = EventMachine::HttpRequest.new("http://#{apiAddress}:8888/api/channel/#{outlet}/#{state}").put

    turnOffHttpRequest.errback do
      TemperatureControl.log text: "#{Time.now} failed to turn #{apiAddress} outlet #{outlet} #{state}"

      GC.start full_mark: true, immediate_sweep: true
    end

    turnOffHttpRequest.callback do
      TemperatureControl.log text: "#{Time.now} turned #{apiAddress} outlet #{outlet} #{state} successfully"

      GC.start full_mark: true, immediate_sweep: true
    end
  end
end

TemperatureControl.readConfig

if TemperatureControl.daemonize

  Process.daemon
end

EventMachine.run do
  TemperatureControl.log text: "#{Time.now}"
  TemperatureControl.log text: 'RPCMs:'
  TemperatureControl.configHash.each do |rpcm, config|
    TemperatureControl.log text: "#{rpcm} #{config['api_address']}"
    EM.add_periodic_timer(2) do
      TemperatureGetter.getTemperatureAndOutletsStates forRPCM: rpcm
    end
  end
end
