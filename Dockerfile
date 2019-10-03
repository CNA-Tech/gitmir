#
# Modified Ubuntu Dockerfile
#
# was originally based on https://github.com/dockerfile/ubuntu
#

# Pull base image.
FROM httpd:2.4

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  add-apt-repository ppa:ondrej/php
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y curl git nano jq software-properties-common php7.1 libapache2-mod-php7.1 php7.1-mcrypt php7.1-cli php7.1-xml php7.1-zip php7.1-mysql php7.1-gd php7.1-imagick php7.1-recode php7.1-tidy php7.1-xmlrpc && \
  rm -rf /var/lib/apt/lists/*

# Add files.
ADD root/.gitmir0.11.sh /usr/local/bin/gitmir
ADD root/.webhookHandler.php /usr/local/apache2/htdocs/webhookHandler.php
ADD root/.initGitmirGlobalCall.sh /usr/local/bin/initGitmirGlobalCall
ADD root/.initGitmirLocalCall.sh /usr/local/bin/initGitmirLocalCall
ADD root/.php.ini /etc/php/7.1/apache2/php.ini
ADD root/.feederFile.json /gitmir/feederFile.json
ADD root/.gitmirhalist.json /gitmir/gitmirhalist.json
ADD root/.start.sh /gitmir/start.sh
ADD root/.httpd.conf /usr/local/apache2/conf/httpd.conf
ADD root/.callGitmir.cgi /usr/local/apache2/cgi-bin/callGitmir.cgi
ADD root/.initGitmirGlobalCall.cgi /usr/local/apache2/cgi-bin/initGitmirGlobalCall.cgi
ADD root/.initGitmirLocalCall.cgi /usr/local/apache2/cgi-bin/initGitmirLocalCall.cgi
ADD root/.index.html /usr/local/apache2/htdocs/index.html


RUN curl https://pksninja-bucket.s3.us-east-2.amazonaws.com/gitmir-github-api -o /gitmir/.token
RUN chmod 755 /usr/local/bin/gitmir
RUN chmod 755 /gitmir/start.sh
RUN chmod 755 /usr/local/bin/initGitmirGlobalCall
RUN chmod 755 /usr/local/bin/initGitmirLocalCall
RUN chmod 755 /usr/local/apache2/cgi-bin/callGitmir.cgi
RUN chmod 755 /usr/local/apache2/htdocs/webhookHandler.php
RUN chmod -R 755 /usr/local/apache2/htdocs
RUN chmod -R 755 /gitmir
RUN chmod -R 755 /usr/local/apache2/cgi-bin
RUN chown -R daemon:daemon /usr/local/apache2/htdocs/
RUN chown -R daemon:daemon /usr/local/apache2/cgi-bin/
RUN chown -R daemon:daemon /gitmir/

EXPOSE 80

CMD /gitmir/start.sh
