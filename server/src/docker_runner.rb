
require_relative './nearest_ancestors'

class DockerRunner

  def initialize(parent)
    @parent = parent
  end

  attr_reader :parent

  def pulled?(image_name)
    image_names.include?(image_name)
  end

  def pull(image_name)
    command = [ sudo, 'docker', 'pull', image_name ].join(space).strip
    _output,_exit_status = shell.exec(command)
  end

  def start(kata_id, avatar_name)
    vol_name = "cyber_dojo_#{kata_id}_#{avatar_name}"
    command = [ sudo, "docker volume create #{vol_name}" ].join(space)
    _output,_exit_status = shell.exec(command)
  end

  def run(image_name, kata_id, avatar_name, max_seconds, delete_filenames, changed_files)
    # 1. Assume volume exists from previous /start
    vol_name = "cyber_dojo_#{kata_id}_#{avatar_name}"

    # 2. Mount the volume into container made from image
    #   --detach       ; get the CID
    #   --interactive  ; we exec later NEEDED????
    # For security...
    #   --net=none
    #   --pids-limit (prevent fork bombs)
    #   --security-opt=no-new-privileges
    #   --user=nobody
    #
    # command= "sudo ... docker create
    #             --interactive
    #             --net=none
    #             --pids-limit=64
    #             --security-opt=no-new-privileges
    #             --user=root
    #             --volume=#{vol_name}:/sandbox
    #             #{image_name} sh"
    #
    # cid = shell.exec(command)

    # 3. Start the container
    #
    # sudo ... docker start #{cid}

    # 4. Delete deleted_filenames from /sandbox in container
    # The F#-NUnit cyber-dojo.sh names the /sandbox folder
    # So SANDBOX has to be /sandbox for backward compatibility.
    # F#-NUnit is the only cyber-dojo.sh that names /sandbox.
    #
    # delete_filenames.each do |filename|
    #   command = "sudo ... docker exec #{cid} sh -c 'rm /sandbox/#{filename}"
    #   shell.exec(command)
    # end

    # 5. Copy changed_files into /sandbox
    #
    # Dir.mktmpdir('differ') do |tmp_dir|
    #   changed_files.each do |filename, content|
    #     disk[tmp_dir].write(filename, content)
    #   end
    #   command = "sudo ... docker cp #{tmp_dir}/ #{cid}:/sandbox"
    #   shell.exec(command)
    # end

    # 6. Ensure changed files are owned by nobody
    #
    # command="docker exec #{cid} sh -c 'chown -R nobody:nobody /sandbox'"
    # shell.exec(command)

    # 7. Ensure user nobody has a home.
    # The existing C#-NUnit image picks up HOME from the *current* user.
    # By default, nobody's entry in /etc/passwd is
    #       nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
    # and nobody does not have a home dir.
    # I usermod to solve this. The C#-NUnit docker image is built
    # from an Ubuntu base which has usermod.
    # Of course, the usermod runs if you are not using C#-NUnit too.
    # In particular usermod is _not_ installed in a default Alpine linux.
    # It's in the shadow package.
    #
    # command = "docker exec #{cid} sh -c 'usermod --home /sandbox nobody 2> /dev/null'"
    # shell.exec(command)

    # 8. Deletegate to docker_runner.sh
    #
    # args = [ cid, max_seconds, quoted(sudo) ].join(space)
    # output, exit_status = shell.cd_exec(my_dir, "./docker_runner.sh #{args}")
    output = 'stubbed'

    # 9. Make sure container is deleted
    # TODO: do this in ensure block for exception safety
    #
    # command = "sudo ... docker rm -f #{cid}"
    # shell.exec(command)

    # output_or_timed_out(output, exit_status, max_seconds)
    output
  end

  private

  include NearestAncestors

  def image_names
    # [docker images] must be made by a user that has sufficient rights.
    # See docker/web/Dockerfile
    command = [sudo, 'docker', 'images'].join(space).strip
    output, _ = shell.exec(command)
    # This will (harmlessly) get all cyberdojofoundation image names too.
    lines = output.split("\n").select { |line| line.start_with?('cyberdojo') }
    lines.collect { |line| line.split[0] }
  end

  def disk
    nearest_ancestors(:disk)
  end

  def shell
    nearest_ancestors(:shell)
  end

  def sudo
    # See sudo comments in Dockerfile
    'sudo -u docker-runner sudo'
  end

  def quoted(s)
    "'" + s + "'"
  end

  def space
    ' '
  end

end
