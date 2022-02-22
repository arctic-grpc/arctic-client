defmodule Hellostreamingworld.HelloRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          num_greetings: String.t()
        }

  defstruct [:name, :num_greetings]

  field(:name, 1, type: :string)
  field(:num_greetings, 2, type: :string)
end

defmodule Hellostreamingworld.HelloReply do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          message: String.t()
        }

  defstruct [:message]

  field(:message, 1, type: :string)
end

defmodule Hellostreamingworld.MultiGreeter.Service do
  @moduledoc false
  use ArcticBase.Service, name: "hellostreamingworld.MultiGreeter"

  rpc(:sayOnce, Hellostreamingworld.HelloRequest, Hellostreamingworld.HelloReply, alias: :say_once)

  rpc(:sayHello, Hellostreamingworld.HelloRequest, stream(Hellostreamingworld.HelloReply),
    alias: :say_hello
  )
end

defmodule Hellostreamingworld.MultiGreeter.Stub do
  @moduledoc false
  use ArcticBase.Stub, service: Hellostreamingworld.MultiGreeter.Service
end
