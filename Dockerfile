# 
# eudaq Dockerfile
# https://github.com/duartej/dockerfiles/eudaq
#
# Creates the environment to run the EUTelescope from the
# duartej/eudaqv1-ubuntu image
#

FROM duartej/eudaqv1-ubuntu:latest
LABEL author="jorge.duarte.campderros@cern.ch" \ 
    version="0.1-alpha" \ 
    description="Docker image for EUTelescope framework"

# Place at the directory
USER root
WORKDIR /eudaq

# Install all dependencies
RUN apt-get update && apt-get -y install \ 
  libeigen3-dev \ 
  default-jdk \ 
  libgsl-dev \ 
  libxpm-dev \ 
  libxft-dev \ 
  libx11-dev \ 
  libxext-dev \
  subversion \ 
  && rm -rf /var/lib/apt/lists/*

# ILCSOFT (for EUTelescope) and LCIO ===================
ENV ILCSOFT /eudaq/ilcsoft
ENV EUTELESCOPE ${ILCSOFT}/v01-19-02/Eutelescope/master/
ENV EUDAQ /eudaq/eudaq
ENV ILCSOFT_CMAKE_ENV ${ILCSOFT}/v01-19-02/ILCSoft.cmake.env.sh
ENV MILLEPEDEII ${ILCSOFT}/v01-19-02/Eutelescope/master/external/millepede2/tags/V04-03-09
ENV MILLEPEDEII_VERSION tags/V04-03-09
ENV GEAR ${ILCOSFT}/v01-19-02/gear/v01-06-eutel-pre
ENV MARLIN ${ILCSOFT}/v01-19-02/Marlin/v01-11
ENV MARLIN_DLL ${EUTELESCOPE}/lib/libEutelescope.so:${EUTELESCOPE}/lib/libEutelProcessors.so:${EUTELESCOPE}/lib/libEutelReaders.so:${EUDAQ}/lib/libNativeReader.so
ENV GBL ${ILCSOFT}/v01-19-02/GBL/V02-01-03
ENV PATH="${PATH}:${MARLIN}/bin:${MILLEPEDEII}:${EUTELESCOPE}/bin:${GEAR}/tools:${GEAR}/bin:${PXARPATH}/bin"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${EUTELESCOPE}/lib:${GEAR}/lib:${GBL}/lib:${PXARPATH}/lib"

COPY release-standalone-tuned.cfg ${ILCSOFT}/release-standalone-tuned.cfg
#  XXX -- PROVISIONAL UNTIL EUTelescope includes new kRD53A
COPY eutelescope.py ${ILCSOFT}/eutelescope_patched.py
#  XXX -- END PROVISIONAL UNTIL EUTelescope includes new kRD53A

# ILCSOFT compilation
RUN mkdir -p ${ILCSOFT} \
  && git clone -b dev-base https://github.com/eutelescope/ilcinstall $ILCSOFT/ilcinstall \
  && cd ${ILCSOFT}/ilcinstall \
  #  XXX -- PROVISIONAL UNTIL EUTelescope includes new kRD53A
  && cp ${ILCSOFT}/eutelescope_patched.py ${ILCSOFT}/ilcinstall/ilcsoft/eutelescope.py \
  #  XXX -- END PROVISIONAL UNTIL EUTelescope includes new kRD53A
  && ${ILCSOFT}/ilcinstall/ilcsoft-install -i -v ${ILCSOFT}/release-standalone-tuned.cfg 
# ILCSOFT (for EUTelescope) and LCIO: DONE ===================

# Recompile eudaq with lcio and eutelescope
RUN . ${ILCSOFT}/v01-19-02/Eutelescope/master/build_env.sh \
  && cd /eudaq/eudaq/build \ 
  && cmake .. -DBUILD_tlu=ON -DBUILD_python=ON -DBUILD_ni=ON -DUSE_LCIO=ON -DBUILD_nreader=ON -DBUILD_cmspixel=ON \ 
  && make -j4 install

USER eudaquser

ENTRYPOINT ACTIVE_PROC=${MARLIN_DLL} && . ${ILCSOFT}/v01-19-02/Eutelescope/master/build_env.sh \ 
    && export MARLIN_DLL=${ACTIVE_PROC} && /bin/bash -i
