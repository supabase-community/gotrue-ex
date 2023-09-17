defmodule GoTrue.ConnCase do
  alias Joken.Signer

  use ExUnit.CaseTemplate

  using do
    quote do
      import GoTrue
    end
  end

  setup tags do
    {:ok, auth_admin_jwt} =
      Signer.sign(
        %{"sub" => "1234567890", "role" => "supabase_admin"},
        Signer.create("HS256", "37c304f8-51aa-419a-a1af-06154e63707a")
      )

    {:ok, conn: GoTrue.client("http://localhost:9998", auth_admin_jwt)}
  end
end
