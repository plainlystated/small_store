default_run_options[:pty] = true
ssh_options[:forward_agent] = true

role :app, *%w[
  lithium.plainlystated.com
]

set :app_dir, "/var/www/creative_retrospection"

task :setup do
  sudo "mkdir #{app_dir}"
  sudo "chown rellik: #{app_dir}"
end

task :deploy do
  `ruby small_store.rb && rsync -avz --delete _web/ lithium:#{app_dir}`
end
