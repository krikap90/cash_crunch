defmodule CashCrunchWeb.Pipelines do


  def on_mount(:default, _params, session, socket) do
    {:cont,
    Phoenix.LiveView.attach_hook(
      socket,
      :common_assigns,
      :handle_params,
      fn _params, url, socket -> {:cont, put_common_assigns(socket, session, url)} end
    )}
  end

  def put_common_assigns(socket, _session, url \\ "/") do
    uri = URI.parse(url)

    Phoenix.Component.assign(socket, :current_path, uri.path)
  end
end
