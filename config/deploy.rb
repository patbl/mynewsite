# config valid only for current version of Capistrano
lock "3.10.2"

set :application, "personal-website"
set :scm, :middleman

namespace :deploy do
  task :create_symlinks do
    on roles(:all) do
      info "Deleting old symbolic links"
      execute "find /home/public -type l -delete"

      info "Creating symbolic links to public directory"
      # Nearly Free Speech requires that symbolic links be relative
      execute "cd /home/public"
      execute "ln -s ../protected/releases/#{File.basename(release_path)}/* /home/public"
    end
  end
end

after :deploy, "deploy:create_symlinks"
