# Temperature Control of Mining Farms based on RPCM ME API

Idea implemented in this script is to monitor temperature and if temperature
goes higher, than set limit, turn devices (for example Mining equipment) off,
and then, when temperature is normal again, turn devices back on

## Installation

bundle install

edit temperatureControl.conf with your favorite text editor

## temperatureControl.conf file format

This file is pure JSON format

First level is name of your RPCM

```
{
  "RPCM1" : {},
  "RPCM2" : {}
}
```

Second level (inside your RPCM name):

```
{
  "api_address":"ip.ad.dr.ess",
  "outlets": {"0":{},"1":{},"2":{},"3":{},"4":{},"5":{},"6":{},"7":{},"8":{},"9":{}}
}
```

Outlet level:

```
{
  "offTemp":50,
  "onTemp":30
}
```

See example temperatureControl.conf file

## Usage

```
ruby temperatureControl.rb -h

Temperature Control Daemon for RPCM ME (http://rpcm.pro)

Usage: temperatureControl.rb [options]
    -d, --daemonize                  Daemonize and return control
    -l, --[no-]log                   Save log to file
    -v, --verbose                    Run verbosely
    -w, --working-directory PATH     Specify working directory (default current directory)
```

## License

This software is licensed under MIT License. See LICENSE.md

## Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
