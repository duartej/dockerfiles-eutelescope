# EUTelescope dockerfile

Creates the environment to run the EUDAQ framework using the image 
provided by duartej/eudaqv1-ubuntu (see [dockerfiles-eudaqv1](https://github.com/duartej/dockerfiles-eudaqv1)
and activating the LCIO and EUTelescope dependencies of EUDAQ.
This package assumes that the [dockerfiles-eudaqv1](https://github.com/duartej/dockerfiles-eudaqv1)
repository is present locally, installed and configured. 

Note that from the ['official' Eutelescope github repository](https://github.com/eutelescope/eutelescope),
under the docker folder you can find Dockerfiles to build docker images 
using the ```ilcinstall``` package. Check what EUDAQ version/branch is built
in there.

## Installation
Assuming ```git```, ```docker``` and ```docker-compose``` is installed on your 
system (host-computer). 

1. Clone the docker eutelescope repository and configure it
```bash 
$ EUDAQDOCKER=<path to dockerfiles-eudaqv1 local folder>
$ git clone -b eutelescope https://github.com/duartej/dockerfiles-eutelescope
$ cd dockerfiles-eutelescope
$ source setup.sh $EUDAQDOCKER
```
The ```setup.sh``` script will create some ```docker-compose*.yml``` files. 

2. Download the automated build from the dockerhub: 
```bash
$ docker pull duartej/eutelescope:latest
```
or alternativelly you can build an image from the [Dockerfile](Dockerfile)
```bash
# Using docker
$ docker build github.com/duartej/eutelescope:latest
# Using docker-compose within the repo directory
$ docker-compose build eutelescope
```
## Usage
Apart from the straightforward usage of EUTelescope, this docker image is 
intended to be used for the EUDAQ framework in subtitution of the `dockerfiles-eudaqv1`
created image, i.e. `duartej/eudaqv1-ubuntu`; as the present docker image supersedes
it by accessing to the LCIO and EUTelescope dependencies. Therefore when using this
image in the `development mode`, be sure re-compile the code in the eudaq repository 
folder by using the proper dependencies:
```bash
$ cd dockerfiles-eutelescope
$ docker-compose run --rm devcode
eudaquser@9ddbd5e1149b:/eudaq$ cd /eudaq/eudaq/build
eudaquser@9ddbd5e1149b:/eudaq$ rm -rf * 
eudaquser@9ddbd5e1149b:/eudaq$ cmake .. -DBUILD_tlu=ON -DBUILD_python=ON -DBUILD_ni=ON -DUSE_LCIO=ON -DBUILD_nreader=ON`
```

### Production environment
The production environment uses the [EUDAQ v1.x-dev](https://github.com/duartej/eudaq/tree/v1.x-dev) branch. 

The **recommended way** to launch all needed services is with _docker-compose_ 
You should be at the _dockerfiles-eutelescope_ repository folder and launch:
```bash 
$ docker-compose -f docker-compose.yml -f production.yml up 
```
One service per each element of the framework (run control, logger, data 
collector, online monitor, TLU producer, ... \<to be defined which are the 
minimum needed\>) is created, all connected to the run control at 
```tcp://172.20.168.2```

To run only one particular service:
```bash
$ docker-compose -f docker-compose.yml -f production.yml run --rm <service_name>
```
note, however, that run control and the logger are always launched as
needed for any of the EUDAQ producers or components. ```service_name``` 
could be: 
 * ```runControl```
 * ```logger```
 * ```dataCollector```
 * ```onlineMon```
 * ```TestProducer```
 * ```NIProducer```
 * ```TLU```

If you want to add other element of the framework, just create a container using 
the ```duartej/eutelescope``` image. Be sure you connect the service to the 
```<foldername>_static_network``` (check your available networks ```docker network
ls```); and assign an unused ip:
```bash
$ docker run --rm -i \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=unix${DISPLAY} \
    --network <foldername>_static_network \
    --ip 172.20.168.XX \
    duartej/eutelescope
# Once inside the container, lauch the process you are 
# interested, and remember to connect (if needed) to run control
# at tcp://172.20.168.2
```

**DISCLAIMER: in alpha yet, not tested in production environments**

### Development environment
The development environment uses the EUDAQ repository placed in the host computer 
at ```$HOME/repos/eudaq```, which was previously cloned and checkout to v1.x-dev 
branch in the installation step of the [dockerfiles-eudaqv1](https://github.com/duartej/dockerfiles-eudaqv1)
package.

Analogously to the production environment, the **recommended way** to launch all
needed services is with _docker-compose_, this time without explicitely especify 
the yaml files (as uses the default and the override mechanism).
```bash 
$ docker-compose up 
```
or launching a concrete service as explained in the production section:
```bash
$ docker-compose run --rm <service_name>
```

An extra service is available in order to allow compilation of the developed code: 
```devcode``` and ```devcode-p``` (the privileged version, to be run for TLU related
check).  The build directory in the container  is found in the ```/eudaq/eudaq/build```: 
```bash
$ docker-compose run --rm devcode
```


