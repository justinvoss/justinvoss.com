
from fabric import tasks
from fabric.api import *
from fabric.contrib.project import rsync_project


env.hosts = ['eldorado']
env.user = 'bleedingwolf'


class PublishTask(tasks.Task):

  name = 'publish'
  
  def run(self):
  
    local('jekyll')
    rsync_project(
      remote_dir = '/srv/justinvoss.com/www',
      local_dir = '_site/',
      exclude = ['Mockup.psd', 'apple-touch-icon.psd', 'Procfile', 'fabfile.py'],
      delete = True
    )
    

publish = PublishTask()
