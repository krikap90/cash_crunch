defmodule CashCrunchWeb.UserForgotPasswordLive do
  use CashCrunchWeb, :live_view

  alias CashCrunch.Accounts

  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Input

  def render(assigns) do
    ~H"""
    <main class="h-screen flex items-center justify-center">
      <div class="grid auto-rows-max items-start gap-4 md:gap-8 lg:col-span-1 ml-12 mt-8">
      <.card>
          <.card_header class="px-7">
            <.card_title>
              Passwort vergessen?
            </.card_title>
            <.card_description>
              Hier kannst du dir ein Passwort Reset schicken lassen
            </.card_description>
          </.card_header>
          <.card_content>
            <div>
              <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
              <.input field={@form[:email]} type="email" placeholder="Email" required />
              <:actions>
                <.button phx-disable-with="Sende..." class="w-full">
                  Sende Passwort Reset
                </.button>
              </:actions>
            </.simple_form>
            <p class="text-center text-sm mt-4">
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

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
