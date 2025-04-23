defmodule CashCrunchWeb.UserRegistrationLive do
  use CashCrunchWeb, :live_view

  alias CashCrunch.Accounts
  alias CashCrunch.Accounts.User

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
              Registriere einen neuen User
            </.card_title>
            <.card_description>
              Schon registriert? Hier geht es zum
              <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
                Login
              </.link>
            </.card_description>
          </.card_header>
          <.card_content>
            <div>
              <.simple_form
                for={@form}
                id="registration_form"
                phx-submit="save"
                phx-change="validate"
                phx-trigger-action={@trigger_submit}
                action={~p"/users/log_in?_action=registered"}
                method="post"
              >
                <.error :if={@check_errors}>
                  Oops, something went wrong! Please check the errors below.
                </.error>

                <.input field={@form[:email]} type="email" placeholder="Email" class="w-[500px]" required />
                <.input field={@form[:password]} type="password" placeholder="Password" class="w-[500px]" required />

                <:actions>
                  <.button phx-disable-with="Erstelle User...">Erstelle User</.button>
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
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
