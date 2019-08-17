# ElixirMock 

![CircleCI Build Status](https://circleci.com/gh/wanderanimrod/elixir_mock.png?style=shield) [![Hex pm](http://img.shields.io/hexpm/v/elixir_mock.svg?style=flat)](https://hex.pm/packages/elixir_mock)

Creates inspectable mocks (test doubles) based on real elixir modules for testing.

The mocks do not replace or modify the original modules the are based on and are fully independent of each other. Because of this isolation, mocks defined from the same real module can be used in multiple tests running in parallel. Also, tests using mocks defined from a real module can run in parallel with other tests that depend on the real module.

## Installation

[Available in Hex](https://hex.pm/packages/elixir_mock). The package can be installed
by adding `elixir_mock` to your list of dependencies in `mix.exs`:
```elixir
def deps do
  [{:elixir_mock, "~> 0.2.8", only: :test}] # or whatever the latest version is
end
```

## Getting started

ElixirMock helps you create inspectable test doubles (mocks) for use within your ExUnit tests.

ElixirMock mocks are just modules defined based on other modules ("real modules"). The mocks are created at compile-time
by copying public functions from the real module to the mock module, with a few modifications that allow calls to the
mock's functions to be recorded and inspected later by tests.

The mocks do not replace or modify in any way the modules  they are based on. They are only meant to be injected as
dependencies into functions under test.

## Example
The example below demonstrates how you would test that a module in your app, `MyApp.User`, makes a call to the
facebook api with the right parameters and returns to you whatever the facebook api returns.

First, let's define a module that wraps the Facebook API. This could be your own module, a module from the standard library,
or one from a hex package.
```elixir
defmodule FacebookClient do
  def get_profile(profile_id) do
    # makes api call to facebook
    :real_facebook_user_profile
  end
end
```

Next, we define a module in our app that we are going to test. This is the module that will go through the
`FacebookClient` to fetch the user's profile from Facebook
```elixir
defmodule MyApp.User do
  # allow function under test to accept injected api client dependency
  def load_user(user_id, facebook_client \\ FacebookClient) do
    facebook_client.get_profile(user_id)
  end
end
```

Now we are ready to test our `MyApp.User` module's `load_user/2` functionality. We will do this without actually hitting
the Facebook API but while still verifying that our code interacts with the api correctly.

```elixir
defmodule MyApp.UserTest do
  use ExUnit.Case, async: true # yes, you can run tests that use mocks in parallel
  require ElixirMock
  import ElixirMock

  test "should get user profile from facebook api when user is loaded" do
    # create mock module with the same functions as the `FacebookClient` module.
    mock_facebook_client = mock_of FacebookClient

    # Call the function you are testing, injecting the mock FacebookClient
    user = MyApp.User.load_user("some-user-id", mock_facebook_client)

    # Check that facebook was called with the user id we passed to MyApp.User.load_user/1
    assert_called mock_facebook_client.get_profile("some-user-id") # passes
  end

end
```

We can even go a step further. We can test that the `MyApp.User.load_user/1` function actually returns what the facebook api returns. To do this, we fix the responses from the Facebook API using the `ElixirMock.defmock_of/2` macro and check that our code returns those fixed responses.
```elixir
defmodule MyApp.UserTest do
  use ExUnit.Case, async: true
  require ElixirMock
  import ElixirMock

  test "load_user/1 returns the response from facebook without any processing." do
    with_mock(mock_facebook_client) = defmock_of FacebookClient do
      def get_profile(_), do: "a custom response from the mock"
    end
    user = MyApp.User.load_user("some-user-id", mock_facebook_client)
    assert user == "a custom response from the mock" # passes
  end
end
```

There's plenty more ElixirMock can do. Please refer to the rest of this page for a gentle introduction to ElixirMock or jump right into [the docs](https://hexdocs.pm/elixir_mock/ElixirMock.html#content) to discover more hidden treasures.

## Characteristics of mocks
- Every mock module has a unique, random UUID atom as its name. You can use `ElixirMock.with_mock/1` to give your mock a fixed human-friendly name.
- All functions on a mock return `nil` unless otherwise specified with the `ElixirMock.defmock_of/2` or
`ElixirMock.defmock_of/3` macros.
- A new mock module is created each time a mock definition is used. Each mock is completely independent of other mocks and does not replace or affect the real module it is based on in any way. This allows you to run tests that make use of mocks in parallel with other tests that use the real modules the mocks are based on, or other tests using mocks based on the same real modules.
- All calls to functions on a mock are recorded by function name and the arguments passed to that function in the call.
- Only public functions are copied from the parent module into the mock. Macros and module attributes are not copied.

## Types of mocks

There are currently two kinds of mocks you can define with ElixirMock

### The simple mock
Simple mocks are defined using the `ElixirMock.mock_of/1` function. They are based on already existing modules (referred to as "parent modules"). Once defined, these mocks inherit all functions defined on the parent module with their implementations stubbed out to return nil. They are called simple mocks because they do not specify any special behaviour for the mock's functions.

Example:

Creating a mock module that has the same api as the in-built elixir `List` module but with its functions returning `nil`.
```elixir
require ElixirMock
import ElixirMock

list_mock = mock_of List
list_mock.first([1, 2]) == nil
#=> true

list_mock.last([1, 2]) == nil
#=> true
```
You can also define the mock to delegate all calls to the real module if you want to record calls to the functions but no alter their behaviour. See the `ElixirMock.mock_of/1` documentation for an example of this and other options.

### Custom mocks
ElixirMock also allows you to define mocks that override some or all of the functions inherited from the module the mocks are based on. This is done using the `ElixirMock.defmock_of/2` and `ElixirMock.defmock_of/3` macros.

__Example:__ Creating a mock of the inbuilt `List` module and overriding its `List.first/1` function.
```elixir
require ElixirMock
import ElixirMock

with_mock(list_mock) = defmock_of List do
  def first(_list), do: :mock_implementation
end

list_mock.first([1, 2]) == :mock_implementation
#=> true
```
For more details on the options available within custom mock definitions, see `ElixirMock.defmock_of/2` and `ElixirMock.defmock_of/3` documentation.


## Verifying calls on mocks

The `ElixirMock.assert_called/1` and `ElixirMock.refute_called/1` macros allow you to verify which calls were made to  mock and which arguments were passed when those calls were made.

These macros take in an expression that looks exactly like the function call you expect to have or not have been made. The function call expressions passed are not executed. Rather, they are deconstructed to get the function name and the arguments. The function name and arguments are then used to find the call in the mocks recorded list of calls.

Example:

```elixir
defmodule MyTest do
  use ExUnit.Case, async: true
  require ElixirMock
  import ElixirMock

  test "verifies that function on mock was called" do
    mock = mock_of List

    mock.first [1, 2]

    assert_called mock.first([1, 2]) # passes
    refute_called mock.first(:some_other_arg) # passes
  end
end
```

For more details on how to do assertions against mocks, see the `ElixirMock.assert_called/1`, `ElixirMock.refute_called/1`, and `ElixirMock.Matchers` documentation pages.


## Managing mock state

While the use of the inbuilt `ElixirMock.assert_called/1` and `ElixirMock.refute_called/1` macros is encouraged for all simple cases, there are cases where access to the raw data stored in the mock is necessary. For those special cases, ElixirMock allows you to interrogate mocks for details on what calls were made to them and what arguments were passed when those calls were made. For further details on how to do this, please refer to the `ElixirMock.Mock` module documentation.

## Contributing
Should you enjoy using this package, please let me know [@wanderanimrod](https://twitter.com/wanderanimrod). If you don't like it for good reasons, please
let me know too. If you find a bug or have a feature or pull request, please create an issue on
[github](https://github.com/wanderanimrod/elixir_mock/issues) and I'll be glad to help.
