defmodule Helloworld.HelloRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t()
        }

  defstruct name: ""

  field(:name, 1, type: :string)
end

defmodule Helloworld.HelloReply do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          message: String.t()
        }

  defstruct message: ""

  field(:message, 1, type: :string)
end

defmodule Helloworld.Greeter.Service do
  @moduledoc false
  use ArcticBase.Service, name: "helloworld.Greeter"

  rpc(:SayHello, Helloworld.HelloRequest, Helloworld.HelloReply, alias: :say_hello)
end

defmodule Helloworld.Greeter.Stub do
  @moduledoc false
  use ArcticBase.Stub, service: Helloworld.Greeter.Service
end
