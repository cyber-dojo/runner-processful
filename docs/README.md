
[![Build Status](https://travis-ci.org/cyber-dojo/runner-processful.svg?branch=master)](https://travis-ci.org/cyber-dojo/runner-processful)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png"
alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

Experimental. Not live.
There are issues securing a process run inside a container using
'docker exec' as opposed to 'docker run'.

# cyberdojo/runner-processful docker image

- A docker-containerized stateful micro-service for [cyber-dojo](http://cyber-dojo.org)
- Runs an avatar's tests.
- A long-lived container holds the state of each practice session.

API:
  * All methods receive their named arguments in a json hash.
  * All methods return a json hash.
    * If the method completes, a key equals the method's name.
    * If the method raises an exception, a key equals "exception".

- - - -

# POST kata_new
Sets up the kata with the given kata_id.
Must be called once before any call to avatar_new with the same kata_id.
- parameters, eg
```
  { "image_name": "cyberdojofoundation/gcc_assert",
       "kata_id": "15B9AD6C42"
  }
```

# POST kata_old
Tears down the kata with the given kata_id.
- parameters, eg
```
  { "image_name": "cyberdojofoundation/gcc_assert",
       "kata_id": "15B9AD6C42"
  }
```

- - - -

# POST avatar_new
Sets up the avatar with the given avatar_name, in the
kata with the given kata_id_, with the given starting files.
Must be called once before any call to run with the same
kata_id and avatar_name.
- parameters, eg
```
  {     "image_name": "cyberdojofoundation/gcc_assert",
           "kata_id": "15B9AD6C42",
       "avatar_name": "salmon",
    "starting_files": { "hiker.h": "#ifndef HIKER_INCLUDED...",
                        "hiker.c": "#include...",
                        ...
                      }
  }
```

# POST avatar_old
Tears down the avatar with the given avatar_name,
in the kata with the given kata_id.
- parameters, eg
```
  {  "image_name": "cyberdojofoundation/gcc_assert",
        "kata_id": "15B9AD6C42",
    "avatar_name": "salmon"
  }
```

- - - -

# POST run_cyber_dojo_sh
Saves the unchanged files, saves the changed_files, saves the new files,
deletes the deleted_files, and runs
cyber-dojo.sh as the avatar with the given avatar_name.
- parameters, eg
```
  {        "image_name": "cyberdojofoundation/gcc_assert",
              "kata_id": "15B9AD6C42",
          "avatar_name": "salmon",
            "new_files": { ... },
        "deleted_files": { ... },
      "unchanged_files": { "cyber-dojo.sh" => "make" },
        "changed_files": { "fizz_buzz.c" => "#include...",
                           "fizz_buzz.h" => "#ifndef FIZZ_BUZZ_INCLUDED...",
                           ...
                         },
          "max_seconds": 10
  }
```
- returns stdout, stderr, status, as the results of calling
cyber-dojo.sh, and colour.
If the run did not complete in max_seconds, colour will be "timed_out".
eg
```
    { "run": {
        "stdout": "...",
        "stderr": "...",
        "status": 137,
        "colour:"timed_out"
      }
    }
```
If the run completed in max_seconds, colour will be "red", "amber", or "green".
eg
```
    { "run": {
        "stdout": "makefile:17: recipe for target 'test' failed\n",
        "stderr": "invalid suffix sss on integer constant",
        "status": 2,
        "colour": "amber"
      }
    }
```
The [traffic-light colour](http://blog.cyber-dojo.org/2014/10/cyber-dojo-traffic-lights.html)
is determined by passing stdout, stderr, and status to a Ruby lambda, read from the
named image, at /usr/local/bin/red_amber_green.rb.
eg
```
lambda { |stdout, stderr, status|
  output = stdout + stderr
  return :red   if /(.*)Assertion(.*)failed./.match(output)
  return :green if /(All|\d+) tests passed/.match(output)
  return :amber
}
```
- If this file does not exist in the named image, the colour is "amber".
- If the contents of this file raises an exception when eval'd or called, the colour is "amber".
- If the lambda returns anything other than :red, :amber, or :green, the colour is "amber".

- - - -
- - - -

# build the docker images
Builds the runner-server image and an example runner-client image.
```
$ ./sh/build_docker_images.sh
```

# bring up the docker containers
Brings up a runner-server container and a runner-client container.

```
$ ./sh/docker_containers_up.sh
```

# run the tests
Runs the runner-server's tests from inside a runner-server container
and then the runner-client's tests from inside the runner-client container.
```
$ ./sh/run_tests_in_containers.sh
```

# run the demo
```
$ ./sh/run_demo.sh
```
Runs inside the runner-client's container.
Calls the runner-server's micro-service methods
and displays their json results and how long they took.
If the runner-client's IP address is 192.168.99.100 then put
192.168.99.100:4558 into your browser to see the output.
- red: tests ran but failed
- amber: tests did not run (syntax error)
- green: tests test and passed
- grey: tests did not complete (in 3 seconds)

# demo screenshot

![red amber green demo](red_amber_green_demo.png?raw=true "red amber green demo")

- - - -

* [Take me to cyber-dojo's home github repo](https://github.com/cyber-dojo/cyber-dojo).
* [Take me to the http://cyber-dojo.org site](http://cyber-dojo.org).

![cyber-dojo.org home page](https://github.com/cyber-dojo/cyber-dojo/blob/master/shared/home_page_snapshot.png)

