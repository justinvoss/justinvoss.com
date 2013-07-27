
from fabric import tasks
from fabric.api import *
from fabric.contrib.project import rsync_project


env.hosts = ['atlantis']
env.user = 'justinvoss'


class PublishTask(tasks.Task):

  name = 'publish'
  
  def run(self):
  
    local('jekyll build')
    rsync_project(
      remote_dir = '/home/justinvoss/justinvoss.com/www',
      local_dir = '_site/',
      exclude = ['fabfile.py', 'fabfile.pyc', 'README.md'],
      delete = True
    )
    

publish = PublishTask()

