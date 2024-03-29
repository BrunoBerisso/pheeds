defmodule PheedsWeb.FeedLive.FormComponent do
  use PheedsWeb, :live_component
  require Logger

  alias Pheeds.SourceFeeds

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage feed records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="feed-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:items_xpath]} type="text" label="Items XPath" />
        <.input field={@form[:title_xpath]} type="text" label="Title XPath" />
        <.input field={@form[:link_xpath]} type="text" label="Link XPath" />
        <.input field={@form[:date_xpath]} type="text" label="Date XPath" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Feed</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{feed: feed} = assigns, socket) do
    changeset = SourceFeeds.change_feed(feed)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"feed" => feed_params}, socket) do
    changeset =
      socket.assigns.feed
      |> SourceFeeds.change_feed(feed_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"feed" => feed_params}, socket) do
    save_feed(socket, socket.assigns.action, feed_params)
  end

  defp save_feed(socket, :edit, feed_params) do
    case SourceFeeds.update_feed(socket.assigns.feed, feed_params) do
      {:ok, feed} ->
        notify_parent({:saved, feed})

        {:noreply,
         socket
         |> put_flash(:info, "Feed updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_feed(socket, :new, feed_params) do
    case SourceFeeds.create_feed(feed_params) do
      {:ok, feed} ->
        notify_parent({:saved, feed})

        {:noreply,
         socket
         |> put_flash(:info, "Feed created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
