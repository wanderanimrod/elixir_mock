# Getting started
ElixirMock mocks are modules defined based on other modules (real modules) for the purpose of acting as test doubles in tests.
Mocks are created at compile-time by copying function specs from the real module into the mock module 
(with some modifications discussed below). 

__Note__: Currently, only functions are ported from parent modules into mocks. Macros and attributes are not ported.

## Characteristics of mocks
- Every mock module has a unique, random UUID atom as its name. You can use `ElixirMock.with_mock/1` to give your mock
  a fixed human-friendly name.
- All functions on a mock return `nil` unless otherwise specified with the `ElixirMock.defmock_of/2` or 
`ElixirMock.defmock_of/3` macros.
- A new mock module is created each time a mock definition is used. Each mock is completely independent of other mocks
 and does not replace or affect the real module it is based on in any way.
- All calls to functions on a mock are recorded by function name and the arguments passed to that function in the call.
- Mocks also have baked-in utility functions. For example, the `mock_context/1` helps with reading context injected into
a mock at definition time.

## Types of mocks

There are currently two kinds of mocks you can define with ElixirMock

### The simple mock
Simple mocks are defined using the `ElixirMock.mock_of/1` function. They are based on the module passed to that function.

Example: 

Creating a mock module that has the same api as the in-built elixir `List` module but with its functions returning `nil`.
```
require ElixirMock
import ElixirMock

list_mock = mock_of List
list_mock.first([1, 2]) == nil 
#=> true

```
You can also define the mock to delegate all calls to the real module if you want to record calls to the functions but not
alter their behaviour. See the `ElixirMock.mock_of/1` documentation for an example of this and other options.

### Custom mocks
ElixirMock also allows you to define mocks that override some or all of the functions inherited from the module the mocks
are based on. This is done using the `ElixirMock.defmock_of/2` and `ElixirMock.defmock_of/3` macros

Example:
```
require ElixirMock
import ElixirMock

with_mock(list_mock) = defmock_of List do
  def first(_list), do: :mock_implementation
end

list_mock.first([1, 2]) == :mock_implementation
#=> true
```
For more details on the options available within custom mock definitions, see `ElixirMock.defmock_of/2` and
`ElixirMock.defmock_of/3` documentation.


## Managing mock state

Mocks can be examined to find out what calls were made to them and what arguments were passed during those calls. See the
`ElixirMock.Mock` module documentation for details.

