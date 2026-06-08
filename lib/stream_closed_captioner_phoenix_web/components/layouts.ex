defmodule StreamClosedCaptionerPhoenixWeb.Layouts do
  @moduledoc false
  use StreamClosedCaptionerPhoenixWeb, :html

  embed_templates "layouts/*"

  @doc """
  Top navigation for the Stream CC marketing pages (homepage, showcase, …).

  Shared chrome rendered by the `:scc` layout. Pass the current user so the
  CTA can adapt, and `active` to mark the current section in the nav.
  """
  attr :current_user, :any, default: nil
  attr :active, :string, default: nil

  def scc_nav(assigns) do
    ~H"""
    <nav class="nav">
      <div class="wrap nav__in">
        <div class="brand-wrap">
          <a class="brand" href={~p"/"}>
            <img class="brand__mark" src={~p"/images/cc100x100.png"} alt="Stream Closed Captioner logo" />Stream&nbsp;CC
          </a>
          <span class="brand__by">
            by
            <a href="https://twitch.tv/talk2megooseman" target="_blank" rel="noopener noreferrer">
              Talk2meGooseman
            </a>
          </span>
        </div>
        <div class="nav__links">
          <a href={~p"/showcase"} aria-current={if @active == "showcase", do: "page"}>Showcase</a>
          <a href={~p"/announcements"} aria-current={if @active == "announcements", do: "page"}>
            Announcements
          </a>
          <a href={~p"/supporters"} aria-current={if @active == "supporters", do: "page"}>
            Supporters
          </a>
          <a
            href="https://talk2megooseman.notion.site/stream-cc-faq"
            target="_blank"
            rel="noopener noreferrer"
          >
            FAQ
          </a>
        </div>
        <div class="nav__cta">
          <%= if @current_user do %>
            <a class="btn btn--primary btn--sm" href={~p"/dashboard"}>Dashboard</a>
            <div class="nav__account" data-controller="dropdown">
              <button
                type="button"
                class="nav__avatar"
                data-action="click->dropdown#toggle"
                aria-label="Account menu"
                aria-haspopup="true"
              >
                <img
                  src={@current_user.profile_image_url || ~p"/images/user-outline.png"}
                  alt={"#{@current_user.login || @current_user.email} profile image"}
                />
              </button>
              <div class="nav__menu hidden" data-target="dropdown.menu" role="menu">
                <p class="nav__menu-name">{@current_user.login || @current_user.email}</p>
                <a href={~p"/users/settings"} class="nav__menu-item" role="menuitem">
                  <svg viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path
                      fill-rule="evenodd"
                      d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  Account Settings
                </a>
                <a href={~p"/users/caption-settings"} class="nav__menu-item" role="menuitem">
                  <svg viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path
                      fill-rule="evenodd"
                      d="M18 10c0 3.866-3.582 7-8 7a8.84 8.84 0 01-2.62-.39 5.77 5.77 0 01-3.064 1.378c-.193.025-.36-.13-.34-.327.024-.213.073-.42.146-.62.1-.27.227-.526.378-.766C3.06 14.74 2 12.5 2 10c0-3.866 3.582-7 8-7s8 3.134 8 7zM7 9H5v2h2V9zm8 0H9v2h6V9z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  Caption Settings
                </a>
                <span class="nav__menu-divider" aria-hidden="true"></span>
                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                  class="nav__menu-item"
                  role="menuitem"
                >
                  <svg viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path
                      fill-rule="evenodd"
                      d="M3 3a1 1 0 00-1 1v12a1 1 0 102 0V4a1 1 0 00-1-1zm10.293 9.293a1 1 0 001.414 1.414l3-3a1 1 0 000-1.414l-3-3a1 1 0 10-1.414 1.414L14.586 9H7a1 1 0 100 2h7.586l-1.293 1.293z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  Log out
                </.link>
              </div>
            </div>
          <% else %>
            <a class="login" href={~p"/users/log_in"}>Log in</a>
            <a class="btn btn--primary btn--sm" href="/auth/twitch">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" aria-hidden="true">
                <path d="M4 3 3 7v12h4v3h3l3-3h4l5-5V3H4Zm16 9-3 3h-4l-3 3v-3H7V5h13v7ZM15 8h2v4h-2V8Zm-5 0h2v4h-2V8Z" />
              </svg>
              Connect with Twitch
            </a>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end

  @doc """
  Footer for the Stream CC marketing pages. Shared chrome rendered by the
  `:scc` layout.
  """
  def scc_footer(assigns) do
    ~H"""
    <footer>
      <div class="wrap">
        <div class="foot__grid">
          <div class="foot__about">
            <a class="brand" href={~p"/"}>
              <img
                class="brand__mark"
                src={~p"/images/cc100x100.png"}
                alt="Stream Closed Captioner logo"
              />Stream&nbsp;CC
            </a>
            <p>
              Closed captions for live streams and calls. Built so every viewer can follow along.
            </p>
            <div class="foot__social">
              <a
                href="https://discord.gg/ZXSqzrc"
                aria-label="Discord"
                target="_blank"
                rel="noopener noreferrer"
              >
                <svg viewBox="0 0 24 24" width="17" height="17" fill="currentColor">
                  <path d="M19 6a16 16 0 0 0-4-1l-.3.6a13 13 0 0 1 5.3 2.7A14 14 0 0 0 5 8.3 13 13 0 0 1 10.3 5.6L10 5a16 16 0 0 0-4 1C3.5 9.5 3 13 3.2 16.4a15 15 0 0 0 4.5 2.3l1-1.6c-.6-.2-1.1-.5-1.6-.8l.4-.3a10 10 0 0 0 9 0l.4.3c-.5.3-1 .6-1.6.8l1 1.6a15 15 0 0 0 4.5-2.3C21 13 20.5 9.5 19 6ZM9.5 14.3c-.8 0-1.5-.8-1.5-1.7s.7-1.7 1.5-1.7 1.5.8 1.5 1.7-.7 1.7-1.5 1.7Zm5 0c-.8 0-1.5-.8-1.5-1.7s.7-1.7 1.5-1.7 1.5.8 1.5 1.7-.7 1.7-1.5 1.7Z" />
                </svg>
              </a>
              <a
                href="https://twitter.com/talk2megooseman"
                aria-label="Twitter / X"
                target="_blank"
                rel="noopener noreferrer"
              >
                <svg viewBox="0 0 24 24" width="17" height="17" fill="currentColor">
                  <path d="M17.5 4h2.6l-5.7 6.5L21 20h-5.3l-4.1-5.4L6.8 20H4.2l6-6.9L4 4h5.4l3.7 4.9L17.5 4Zm-1 14.4h1.5L8.6 5.5H7L16.5 18.4Z" />
                </svg>
              </a>
              <a
                href="https://patreon.com/talk2megooseman"
                aria-label="Patreon"
                target="_blank"
                rel="noopener noreferrer"
              >
                <svg viewBox="0 0 24 24" width="17" height="17" fill="currentColor">
                  <path d="M15.4 3c-4 0-7.2 3.2-7.2 7.2 0 3.9 3.2 7.1 7.2 7.1 3.9 0 7.1-3.2 7.1-7.1C22.5 6.2 19.3 3 15.4 3ZM2 21V3h3.3v18H2Z" />
                </svg>
              </a>
              <a
                href="https://ko-fi.com/talk2megooseman"
                aria-label="Ko-fi"
                target="_blank"
                rel="noopener noreferrer"
              >
                <svg viewBox="0 0 24 24" width="17" height="17" fill="currentColor">
                  <path d="M11.351 2.715c-2.7 0-4.986.025-6.83.26C2.078 3.285 0 5.154 0 8.61c0 3.506.182 6.13 1.585 8.493 1.584 2.701 4.233 4.182 7.662 4.182h.83c4.209 0 6.494-2.234 7.637-4a9.5 9.5 0 0 0 1.091-2.338C21.792 14.688 24 12.22 24 9.208v-.415c0-3.247-2.13-5.507-5.792-5.87-1.558-.156-2.65-.208-6.857-.208m0 1.947c4.208 0 5.09.052 6.571.182 2.624.311 4.13 1.584 4.13 4v.39c0 2.156-1.792 3.844-3.87 3.844h-.935l-.156.649c-.208 1.013-.597 1.818-1.039 2.546-.909 1.428-2.545 3.064-5.922 3.064h-.805c-2.571 0-4.831-.883-6.078-3.195-1.09-2-1.298-4.155-1.298-7.506 0-2.181.857-3.402 3.012-3.714 1.533-.233 3.559-.26 6.39-.26m6.547 2.287c-.416 0-.65.234-.65.546v2.935c0 .311.234.545.65.545 1.324 0 2.051-.754 2.051-2s-.727-2.026-2.052-2.026m-10.39.182c-1.818 0-3.013 1.48-3.013 3.142 0 1.533.858 2.857 1.949 3.897.727.701 1.87 1.429 2.649 1.896a1.47 1.47 0 0 0 1.507 0c.78-.467 1.922-1.195 2.623-1.896 1.117-1.039 1.974-2.364 1.974-3.897 0-1.662-1.247-3.142-3.039-3.142-1.065 0-1.792.545-2.338 1.298-.493-.753-1.246-1.298-2.312-1.298" />
                </svg>
              </a>
            </div>
          </div>

          <div class="foot__col">
            <h4>Product</h4>
            <a href={~p"/showcase"}>Showcase</a>
            <a href={~p"/announcements"}>Announcements</a>
            <a
              href="https://talk2megooseman.notion.site/stream-cc-faq"
              target="_blank"
              rel="noopener noreferrer"
            >
              FAQ
            </a>
          </div>
          <div class="foot__col">
            <h4>Community</h4>
            <a href={~p"/supporters"}>Supporters</a>
            <a href="https://discord.gg/ZXSqzrc" target="_blank" rel="noopener noreferrer">
              Discord
            </a>
            <a href="https://patreon.com/talk2megooseman" target="_blank" rel="noopener noreferrer">
              Patreon
            </a>
            <a href="https://ko-fi.com/talk2megooseman" target="_blank" rel="noopener noreferrer">
              Ko-fi
            </a>
          </div>
          <div class="foot__col">
            <h4>Legal</h4>
            <a href={~p"/privacy"}>Privacy</a>
            <a href={~p"/terms"}>Terms</a>
          </div>
        </div>
        <div class="foot__bar">
          <span>© {Date.utc_today().year} Erik Guzman</span>
        </div>
      </div>
    </footer>
    """
  end
end
