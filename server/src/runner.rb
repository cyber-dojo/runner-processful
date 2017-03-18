
def runner_class_name(image_name)
  class_name ||= 'DockerContainerRunner' if container_runner?(image_name)
  class_name ||= 'DockerVolumeRunner'    if volume_runner?(image_name)
  class_name ||= 'DockerVolumeRunner'    # default
  autoload(:DockerContainerRunner, '/app/src/docker_container_runner.rb') if class_name == 'DockerContainerRunner'
  autoload(:DockerVolumeRunner,    '/app/src/docker_volume_runner.rb')    if class_name == 'DockerVolumeRunner'
  class_name
end

def volume_runner?(image_name)
  image_name.end_with?(':shared_disk')
end

def container_runner?(image_name)
  image_name.end_with?(':shared_process')
end

module Runner # mix-in

  def runner
    new_runner(image_name, kata_id)
  end

  def new_runner(image_name, kata_id)
    Object.const_get(runner_class_name(image_name)).new(self, image_name, kata_id)
  end

end
