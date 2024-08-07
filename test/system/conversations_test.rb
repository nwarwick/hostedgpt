require "application_system_test_case"

class ConversationsTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
    @starting_path = current_path
  end

  test "options icon shows a tooltip" do
    convo = hover_conversation conversations(:greeting)
    assert_shows_tooltip convo.find_role("options"), "Options"
  end

  test "clicking conversation edit option enables edit, unfocusing submits it" do
    convo = hover_conversation conversations(:greeting)
    edit = convo.find_role("edit")

    convo.find_role("options").click
    assert_true { edit.visible? }
    edit.click

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    find("body").click
    sleep 1

    assert_equal "Meeting Samantha Jones", convo.text
    assert_equal "Meeting Samantha Jones", conversations(:greeting).reload.title
  end

  test "clicking conversation edits icon enables edit, pressing Enter submits it" do
    convo = hover_conversation conversations(:greeting)
    edit = convo.find_role("edit")

    convo.find_role("options").click
    assert_true { edit.visible? }
    edit.click

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    send_keys "enter"
    sleep 1

    assert_equal "Meeting Samantha Jones", convo.text
    assert_equal "Meeting Samantha Jones", conversations(:greeting).reload.title
  end

  test "clicking conversation edits it and pressing Esc aborts the edit and does not save" do
    convo_dom_elem = hover_conversation conversations(:greeting)
    old_text = conversations(:greeting).title # "Meeting Samantha"
    edit = convo_dom_elem.find_role("edit")

    convo_dom_elem.find_role("options").click
    assert_true { edit.visible? }
    edit.click

    fill_in "edit-conversation", with: "Meeting Linda"
    send_keys "esc"

    assert_true "UI never reverted back to the old title '#{old_text}'" do
      convo_dom_elem.text == old_text
    end
    assert_equal "Meeting Samantha", conversations(:greeting).reload.title
  end

  test "clicking the conversation delete, when you ARE NOT on this conversation, deletes it and the url does not change" do
    convo = hover_conversation conversations(:greeting)
    delete = convo.find_role("delete")

    convo.find_role("options").click
    assert_true { delete.visible? }
    delete.click

    assert_toast "Deleted conversation"
    assert_current_path(@starting_path)
  end

  test "clicking the conversation delete, when you ARE not on this conversation, deletes it and redirects you to a new conversation" do
    visit_and_scroll_wait conversation_messages_path(conversations(:greeting))
    convo = hover_conversation conversations(:greeting)
    options = convo.find_role("options")
    delete = convo.find_role("delete")

    options.click
    assert_true { delete.visible? }
    delete.click

    assert_toast "Deleted conversation"
    assert_current_path new_assistant_message_path(users(:keith).assistants.ordered.first)
  end

  private

  def hover_conversation(c)
    assert_visible "#conversation-#{c.id} a[data-role='title']"
    convo_node = find("#conversation-#{c.id}")
    convo_node.hover
    convo_node
  end
end
