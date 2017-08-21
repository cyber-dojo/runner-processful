require_relative '../hex_mini_test'
require_relative '../../src/runner_service'

class TestBase < HexMiniTest

  def runner
    RunnerService.new
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def image_pulled?(named_args = {})
    runner.image_pulled?(*defaulted_args(__method__, named_args))
  end

  def image_pull(named_args = {})
    runner.image_pull(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?(named_args = {})
    runner.kata_exists?(*defaulted_args(__method__, named_args))
  end

  def kata_new(named_args = {})
    runner.kata_new(*defaulted_args(__method__, named_args))
  end

  def kata_old(named_args = {})
    runner.kata_old(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(named_args = {})
    runner.avatar_exists?(*defaulted_args(__method__, named_args))
  end

  def avatar_new(named_args = {})
    runner.avatar_new(*defaulted_args(__method__, named_args))
  end

  def avatar_old(named_args = {})
    runner.avatar_old(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def sss_run(named_args = {})
    # don't call this run() as it clashes with MiniTest
    @sss = runner.run(*defaulted_args(__method__, named_args))
  end

  def sss
    @sss
  end

  def status; sss['status']; end
  def stdout; sss['stdout']; end
  def stderr; sss['stderr']; end
  def colour; sss['colour']; end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def defaulted_args(method, named_args)
    method = method.to_s
    args = []

    args << defaulted_arg(named_args, :image_name, default_image_name)
    args << defaulted_arg(named_args, :kata_id, default_kata_id)
    return args if method == 'image_pulled?'
    return args if method == 'image_pull'
    return args if method == 'kata_exists?'
    return args if method == 'kata_new'
    return args if method == 'kata_old'

    args << defaulted_arg(named_args, :avatar_name, default_avatar_name)
    return args if method == 'avatar_exists?'
    return args if method == 'avatar_old'

    if method == 'avatar_new'
      args << defaulted_arg(named_args, :starting_files, files)
      return args
    end

    args << defaulted_arg(named_args, :deleted_filenames, [])
    args << defaulted_arg(named_args, :changed_files, files)
    args << defaulted_arg(named_args, :max_seconds, 10)
    return args if method == 'sss_run'
  end

  def defaulted_arg(named_args, arg_name, arg_default)
    named_args.key?(arg_name) ? named_args[arg_name] : arg_default
  end

  def default_image_name
    "#{cdf}/gcc_assert"
  end

  def default_kata_id
    test_id + '0' * (10-test_id.length)
  end

  def default_avatar_name
    'salmon'
  end

  def cdf
    'cyberdojofoundation'
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def files
    @files ||= read_files
  end

  def read_files
    filenames =%w( hiker.c hiker.h hiker.tests.c cyber-dojo.sh makefile )
    Hash[filenames.collect { |filename|
      [filename, IO.read("/app/test/start_files/gcc_assert/#{filename}")]
    }]
  end

  def file_sub(name, from, to)
    files[name] = files[name].sub(from, to)
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def assert_success; assert_equal success, status, sss.to_s; end
  def refute_success; refute_equal success, status, sss.to_s; end

  def assert_timed_out; assert_equal timed_out, status, sss.to_s; end

  def assert_stdout(expected); assert_equal expected, stdout, sss.to_s; end
  def assert_stderr(expected); assert_equal expected, stderr, sss.to_s; end
  def assert_status(expected); assert_equal expected, status, sss.to_s; end
  def assert_colour(expected); assert_equal expected, colour, sss.to_s; end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def success; 0; end
  def timed_out; 'timed_out'; end

end
