defmodule CashCrunchWeb.UserSettingsLive do
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
              User Einstellungen
            </.card_title>
            <.card_description>
              Hier kannst du deine User Einstellungen ändern
            </.card_description>
          </.card_header>
          <.card_content>
            <div>
              <.simple_form
                for={@email_form}
                id="email_form"
                phx-submit="update_email"
                phx-change="validate_email"
              >
                <.input field={@email_form[:email]} type="email" placeholder="Email"  class="w-[500px]" required />
                <.input
                  field={@email_form[:current_password]}
                  name="current_password"
                  id="current_password_for_email"
                  type="password"
                  placeholder="Current password"
                  value={@email_form_current_password}
                   class="w-[500px]"
                  required
                />
                <:actions>
                  <.button phx-disable-with="Changing...">Change Email</.button>
                </:actions>
              </.simple_form>
            </div>
            <div>
              <.simple_form
                for={@password_form}
                id="password_form"
                action={~p"/users/log_in?_action=password_updated"}
                method="post"
                phx-change="validate_password"
                phx-submit="update_password"
                phx-trigger-action={@trigger_submit}
              >
                <input
                  name={@password_form[:email].name}
                  type="hidden"
                  id="hidden_user_email"
                  value={@current_email}
                   class="w-[500px]"
                />
                <.input field={@password_form[:password]} type="password" placeholder="New password" class="w-[500px]" required />
                <.input
                  field={@password_form[:password_confirmation]}
                  type="password"
                  placeholder="Confirm new password"
                   class="w-[500px]"
                />
                <.input
                  field={@password_form[:current_password]}
                  name="current_password"
                  type="password"
                  placeholder="Current password"
                  id="current_password_for_password"
                  value={@current_password}
                   class="w-[500px]"
                  required
                />
                <:actions>
                  <.button phx-disable-with="Changing...">Change Password</.button>
                </:actions>
              </.simple_form>
            </div>
          </.card_content>
        </.card>
      </div>
    </main>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
