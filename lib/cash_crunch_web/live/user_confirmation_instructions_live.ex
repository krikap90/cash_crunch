defmodule CashCrunchWeb.UserConfirmationInstructionsLive do
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
              No confirmation instructions received?
            </.card_title>
            <.card_description>
              We'll send a new confirmation link to your inbox
            </.card_description>
          </.card_header>
          <.card_content>
            <div>
              <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
                <.input field={@form[:email]} type="email" placeholder="Email" required />
                <:actions>
                  <.button phx-disable-with="Sending..." class="w-full">
                    Resend confirmation instructions
                  </.button>
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

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
