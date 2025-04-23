defmodule CashCrunchWeb.UserConfirmationLive do
  use CashCrunchWeb, :live_view

  alias CashCrunch.Accounts

  import SaladUI.Button
  import SaladUI.Card

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <main class="h-screen flex items-center justify-center">
      <div class="grid auto-rows-max items-start gap-4 md:gap-8 lg:col-span-1 ml-12 mt-8">
      <.card>
          <.card_header class="px-7">
            <.card_title>
              Bestätige den User
            </.card_title>
            <.card_description>
              Hier kannst du deinen User bestätigen
            </.card_description>
          </.card_header>
          <.card_content>
            <div>
              <.simple_form for={@form} id="confirmation_form" phx-submit="confirm_account">
                <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
                <:actions>
                  <.button phx-disable-with="Bestätige..." class="w-full">Bestätige meinen User</.button>
                </:actions>
              </.simple_form>

              <p class="text-center mt-4">
                <.link href={~p"/users/register"}>Registrieren</.link>
                | <.link href={~p"/users/log_in"}>Login</.link>
              </p>
            </div>
          </.card_content>
        </.card>
      </div>
    </main>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User confirmed successfully.")
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "User confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end
end
