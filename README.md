<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [automated_testing_framework_server_websocket](#automated_testing_framework_server_websocket)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Installation](#installation)
    - [Build from Source](#build-from-source)
    - [Using Pub](#using-pub)
  - [Customization](#customization)
    - [Authentication](#authentication)
    - [Authorization](#authorization)
    - [Commands](#commands)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# automated_testing_framework_server_websocket

## Table of Contents

* [Introduction](#introduction)
* [Installation](#installation)
  * [Build from Source](#build-from-source)
  * [Using Pub](#using-pub)
* [Customization](#customization)
  * [Authentication](#authentication)
  * [Authorization](#authorization)
  * [Commands](#commands)


---

## Introduction



---

## Installation

### Build from Source

To build from source, clone the repo:

```
https://github.com/peiffer-innovations/automated_testing_framework_server_websocket
```

Then execute the command:
```
dart compile exe bin/run.dart
```

That will create an executable named `run` in the `output` directory that can be used to start the server.

---

### Using Pub

Installation via Pub is straight forward.  Execute the following command:

```
pub global activate automated_testing_framework_server_websocket
```

Then to start the server, execute:
```
pub global run automated_testing_framework_server_websocket:run
```

---

## Customization

This server is designed to allow developers the ability to easily extend and customize it.  Developers can provide a custom authentication scheme and / or the ability to execute custom commands.

Customizing the server begins with adding this package as a dependency in your own custom Dart project:
```yaml
dependencies: 
  automated_testing_framework_server_websocket: <version>
```

Next, create your own `bin/run.dart` file.  See [the default run.dart](https://github.com/peiffer-innovations/automated_testing_framework_server_websocket/blob/main/bin/run.dart) as an example starting point.


---

### Authentication

In order to customize the authentication mechanism, extend the [Authentication](https://github.com/peiffer-innovations/automated_testing_framework_server_websocket/blob/main/lib/src/security/authentication/authenticator.dart) class and implement the `authenticate` function.  Then pass the custom authenticator to the `Server` at initialization time.



---

### Authorization

In order to customize the authorization mechanism, extend the [Authorizer](https://github.com/peiffer-innovations/automated_testing_framework_server_websocket/blob/main/lib/src/security/authorization/authorizer.dart) class and implement the `authorize` function.  Then pass the custom authenticator to the `Server` at initialization time.


---

### Commands

The [Server](https://pub.dev/documentation/automated_testing_framework_server_websocket/latest/automated_testing_framework_server_websocket/Server-class.html) accepts a series of `handlers` that can be used perform custom actions when commands are received.