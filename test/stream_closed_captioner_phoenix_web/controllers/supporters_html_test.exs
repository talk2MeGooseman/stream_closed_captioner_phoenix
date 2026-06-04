defmodule StreamClosedCaptionerPhoenixWeb.SupportersHTMLTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias StreamClosedCaptionerPhoenixWeb.SupportersHTML

  describe "initials/1" do
    test "uses the first letters of the first two words" do
      assert SupportersHTML.initials("Troy Cusack") == "TC"
      assert SupportersHTML.initials("Max Pitsaer") == "MP"
    end

    test "ignores punctuation and underscores when splitting names" do
      assert SupportersHTML.initials("Paige ☆ Hex") == "PH"
      assert SupportersHTML.initials("joe_dNs") == "JO"
    end

    test "falls back to the first two characters for single-word names" do
      assert SupportersHTML.initials("kiaraakitty") == "KI"
      assert SupportersHTML.initials("Onyx") == "ON"
    end

    test "falls back to a star when there are no alphanumeric characters" do
      assert SupportersHTML.initials("💜") == "★"
      assert SupportersHTML.initials("") == "★"
    end
  end

  describe "avatar_style/1" do
    test "is deterministic for a given name" do
      assert SupportersHTML.avatar_style("Troy Cusack") ==
               SupportersHTML.avatar_style("Troy Cusack")
    end

    test "produces a gradient built from a palette color" do
      style = SupportersHTML.avatar_style("Aminoanic")
      assert style =~ "linear-gradient"
      assert Regex.match?(~r/#[0-9A-Fa-f]{6}/, style)
    end
  end

  describe "partition_patrons/1" do
    test "splits currently-entitled from lapsed and drops never-supporters" do
      patrons = [
        %{
          "fullName" => "Active A",
          "currentlyEntitledAmountCents" => 500,
          "campaignLifetimeSupportCents" => 5000
        },
        %{
          "fullName" => "Former F",
          "currentlyEntitledAmountCents" => 0,
          "campaignLifetimeSupportCents" => 1500
        },
        %{
          "fullName" => "Never N",
          "currentlyEntitledAmountCents" => 0,
          "campaignLifetimeSupportCents" => 0
        }
      ]

      assert {[%{"fullName" => "Active A"}], [%{"fullName" => "Former F"}]} =
               SupportersHTML.partition_patrons(patrons)
    end
  end

  describe "patron_card/1" do
    test "renders the name, monogram, and active tier" do
      html =
        render_component(&SupportersHTML.patron_card/1, patron: %{"fullName" => "Troy Cusack"})

      assert html =~ "Troy Cusack"
      assert html =~ "TC"
      assert html =~ "Active Patron"
      assert html =~ "pcard"
    end
  end

  describe "patron_chip/1" do
    test "renders the name and monogram dot" do
      html =
        render_component(&SupportersHTML.patron_chip/1, patron: %{"fullName" => "Suz Hinton"})

      assert html =~ "Suz Hinton"
      assert html =~ "SH"
      assert html =~ "fchip"
    end
  end

  describe "index/1 (full page)" do
    test "renders the hero, active grid with join card, and former chips" do
      data = %{
        "patreon" => %{
          "campaignMembers" => [
            %{
              "fullName" => "Active A",
              "currentlyEntitledAmountCents" => 500,
              "campaignLifetimeSupportCents" => 5000
            },
            %{
              "fullName" => "Former F",
              "currentlyEntitledAmountCents" => 0,
              "campaignLifetimeSupportCents" => 1500
            }
          ]
        }
      }

      html = render_component(&SupportersHTML.index/1, data: data)

      # hero + Patreon CTA
      assert html =~ "Help keep the"
      assert html =~ "Become a Supporter"
      assert html =~ "Active patrons"
      assert html =~ "Supporters all-time"
      # active card, join card, and former chip
      assert html =~ "Active A"
      assert html =~ "Want to see your name here?"
      assert html =~ "Former patrons"
      assert html =~ "Former F"
      assert html =~ "Every name here helped caption a stream"
    end

    test "omits the patron sections when there are no supporters" do
      html =
        render_component(&SupportersHTML.index/1,
          data: %{"patreon" => %{"campaignMembers" => []}}
        )

      # hero still renders; patron sections (join card + former footer) do not
      assert html =~ "Help keep the"
      refute html =~ "Want to see your name here?"
      refute html =~ "Former patrons"
      refute html =~ "Every name here helped caption a stream"
    end
  end
end
