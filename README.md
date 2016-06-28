github-todotxt
==============

A utility to sync [Github](https://github.com/) issues that have been assigned
to you with your [todotxt](http://todotxt.com/) so you have one place to keep
all the things you have to do.

License
-------

Copyright 2016 Evan Prodromou <evan@prodromou.name>

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

Install
-------

The easiest way to install is to use [npm](http://npmjs.org/):

```shell
npm install -g github-todotxt
```

You can also fork the repository.

Authentication
--------------

You need an [OAuth](https://developer.github.com/v3/oauth/) token from Github to
run github-todotxt.

Usage
-----

The script takes the following arguments:

* ***-t*** (***--token***): The OAuth token for your account. You can get one at
  going to https://github.com/settings/tokens . Note that Github only shows the
  token once, so copy-and-paste it!
* ***-f*** (***--file***): Path to your todo.txt file. The default is
  `$HOME/Dropbox/todo/todo.txt`, where `$HOME` is your home directory. Note that
  this file will be written to! We'll make a backup, though.
* ***-q*** (***--quiet***): Make the output less noisy. It's not that loud, but
  maybe you want it really, really quiet.
* ***-c*** (***--config***): Path to the config file (see config file section
  below). If you don't provide this argument, the default is
  `$HOME/github-todotxt.json`.
* ***-h*** (***--help***): Show pretty much this help output.

Config file
-----------

You can put options into the config file (`$HOME/github-todotxt.json` by
default). It's just a [JSON](http://json.org/) file, with a single object in it,
with one property for each command-line option, like `token` or `file`.

For example:

```json
{
  "token": "abcdefghijklmnopqrstuvwxyz01234567890",
  "file": "/home/evan/github/todo.txt"
}
```

Environment variables
---------------------

You can also set environment variables (like in your `.bashrc`) for each of the
configuration options. Just all-caps the option long name and prepend
`GITHUB_TODOTXT_`, like `GITHUB_TODOTXT_TOKEN` or `GITHUB_TODOTXT_FILE`.

todo.txt lines
--------------

`github-todotxt` looks for lines with the `issue:` metadata prefix in them, kind
of like this:

```
(B) 2016-06-27 Use a configuration file issue:evanp/github-todotxt#5 +GithubTodotxt
```

It will automatically close todo.txt items for issues that have been closed on
Github.

It will automatically add todo.txt items for issues that exist on Github that
don't exist in todo.txt.

It looks at all Github issues in all repositories you have access to. It only
syncs with issues that are assigned to you.

It creates automatic project markers, based on the repository name.
