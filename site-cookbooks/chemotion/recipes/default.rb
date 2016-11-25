include_recipe 'apt'

include_recipe "users"

# install git
package 'git'

package 'libpq-dev'

include_recipe "postgresql::server"
include_recipe "postgresql::client"
include_recipe "postgresql::libpq"

postgresql_user "dev" do
  superuser true
  createdb true
  login true
  replication false
  password "password!"
end

postgresql_database "chemotion_production" do
  owner "dev"
  encoding "UTF-8"
  template "template0"
  locale "en_US.UTF-8"
end

# gem 'nokogiri' dependency
package 'libxml2'

# gem imagemagick dependency
package 'imagemagick'
package 'libmagickwand-dev'

# package to generate png image from svg
package 'inkscape'

# OpenBabel dependency
package 'cmake'

include_recipe 'rvm::user'
include_recipe 'nvm'
include_recipe 'phusionpassenger::default'

nvm_install 'v4.4.3'  do
  user 'dev'
  group 'dev'
  from_source false
  alias_as_default true
  action :create
end

app_root = '/home/dev/www/chemotion'

# Create rails directories
%w(/ releases shared shared/bin shared/config shared/log shared/tmp shared/pids).each do |directory|
  directory "#{app_root}/#{directory}" do
    user         'dev'
    group         'dev'
    mode          '0755'
    recursive     true
  end
end

deploy app_root do
  repo 'https://github.com/ComPlat/chemotion_ELN.git'
  user 'dev'
  group 'dev'
  migrate true
  environment 'RAILS_ENV' => 'production'
  migration_command "bash -l -c \"rake db:migrate --trace\""
  create_dirs_before_symlink  %w{tmp public config deploy}

  before_migrate do
    current_release = release_path

    link "#{release_path}/config/database.yml" do
      to "#{app_root}/shared/config/database.yml"
    end

    link "#{release_path}/.env" do
      to "#{app_root}/shared/.env"
    end

    execute "Gem bundler install" do
      user 'dev'
      # TODO: cwd release_path
      command("bash -l -c \"cd #{release_path} && gem install bundler\"")
      action :run
    end

    execute "ruby gems" do
      user 'dev'
      command("bash -l -c \"cd #{release_path} && rvm rubygems 2.6.3\"")
      action :run
    end

    execute "Bundle install" do
      user 'dev'
      # TODO: cwd release_path
      command("bash -l -c \"cd #{release_path} && bundle install\"")
      action :run
    end

    execute "Update NPM" do
      user 'dev'
      command "bash -l -c \"npm install -g npm@3.10.8\""
      action :run
    end

    execute "Install packages with NPM" do
      command "bash -l -c \"cd #{release_path} && npm install\""
      action :run
    end

    template "#{app_root}/shared/config/database.yml" do
      source  'database.yml.erb'
      owner   'dev'
      group   'dev'
    end

    template "#{app_root}/shared/.env" do
      source  '.env'
      owner   'dev'
      group   'dev'
    end
  end

  before_restart do
    execute "Precompile assets" do
      command "bash -l -c \"cd #{release_path} && RAILS_ENV=production rake assets:precompile\""
      action :run
    end

    passenger_site 'creating_site' do
      document_root '/home/dev/www/chemotion/current/public'
      environment 'USER' => 'dev', 'HOME' => '/home/dev'
      server_name '141.52.97.236'
      server_alias %w(localhost)
      user 'dev'
    end

    passenger_site 'enabling_site' do
      server_name '141.52.97.236'
      action :enable
    end
  end
end
