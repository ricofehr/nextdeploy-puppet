# nextdeploy-puppet

The puppet repository who manages the virtual machines installation for the [nextdeploy project](https://github.com/ricofehr/nextdeploy) users

## Submodules and Clone

The puppet modules of the community are included in the project in the form of Submodules git.

To retrieve, use this clone cmd.
```
git clone --recursive git@github.com:ricofehr/nextdeploy-puppet
```

If the clone has already been done, execute this command.
```
git submodule update --init
```

## Test / Development

A script "up" allows test and validation of puppet classes and modules.

Prerequisites for this use are vagrant, curl, wget, git, rsync, php installed on the system.
```
  Usage: ./up [options]

  -h           this is some help text.
  -o xxxx      operating system, choices are Ubuntu1404, Debian8, Ubuntu1604. Default is Ubuntu1404
  -f xxxx      project framework(s), choices are drupal7 drupal8 symfony2 symfony3
                                                wordpress nodejs reactjs static noweb
                                                drupal8-reactjs drupal8-symfony3 symfony2-static
               No default, ask to user if not setted
  -t xxxx      Add a techno to the default framework list (look puppet class for add correct techno module)
```

## Contributing

1. Fork it.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create new Pull Request.
