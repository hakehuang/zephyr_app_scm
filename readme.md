#Introduce

this is a app configuration managerment tool for [zephyr-rtos](https://github.com/zephyrproject-rtos/zephyr)

#prerequsite

install ruby 2.4 above [rube-lang](https://www.ruby-lang.org/en/)
cd to the project top folder, run below
```
gem install bundle
bundle update
```

#in boards/scropts 

run the individual board rb file, e.g.

```
  ruby ./frdm_k64f.rb
```

#the output will be in the pipe_file

currently only jenkins pipeline out put supports

#Note:
currently only NXP boards configs available 
