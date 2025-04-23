defmodule CashCrunchWeb.UserLoginLive do
  use CashCrunchWeb, :live_view

  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Checkbox
  import SaladUI.Input

  def render(assigns) do
    ~H"""
    <main class="h-screen flex items-center justify-center">
      <div class="grid auto-rows-max items-start gap-4 md:gap-8 lg:col-span-1 ml-12 mt-8">
      <.card>
          <.card_header class="px-7">
            <.card_title>
              Melde dich an
            </.card_title>
            <.card_description>
              Noch keinen User?
              <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
                Hier
              </.link>
              kannst du dich registrieren
            </.card_description>
          </.card_header>
          <.card_content>
            <div>
              <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
                <.input field={@form[:email]} type="email" placeholder="Email" required />
                <.input field={@form[:password]} type="password" placeholder="Password" required />

                <div className="flex items-center space-x-2">
                  <.label for="checked"><.checkbox id="checked" field={@form[:remember_me]}/> Eingeloggt bleiben</.label>
                </div>
                <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
                  Passwort vergessen?
                </.link>
                <:actions>
                  <.button phx-disable-with="Logging in..." class="w-full">
                    Log in <span aria-hidden="true">→</span>
                  </.button>
                </:actions>
              </.simple_form>
            </div>
          </.card_content>
        </.card>
      </div>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
