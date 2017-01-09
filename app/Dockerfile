FROM ruby:2.3.1

RUN ruby --version
RUN mkdir -p /app

ADD Gemfile /app
ADD Gemfile.lock /app
WORKDIR /app

RUN gem install bundler && bundle install --jobs 4 --retry 5

ADD . /app

CMD bundle exec ruby app.rb -p 8002 -o 0.0.0.0
