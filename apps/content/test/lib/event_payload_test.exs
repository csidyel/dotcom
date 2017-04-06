defmodule Content.EventPayloadTest do
  use ExUnit.Case, async: true
  import Content.FixtureHelpers
  import Content.EventPayload

  @meeting "cms_migration/meeting.json"
  @meeting_missing_end_time "cms_migration/meeting_missing_end_time.json"

  describe "from_meeting/1" do
    test "maps meeting information to CMS event fields" do
      meeting = fixture(@meeting)

      event_payload = from_meeting(meeting)

      assert event_payload[:type] == [%{target_id: "event"}]
      assert event_payload[:title] == [%{value: "Fare Increase Proposal"}]
      assert event_payload[:body] == [%{value: "Discuss fare increase proposal."}]
      assert event_payload[:field_who] == [%{value: "Staff"}]
      assert event_payload[:field_imported_address] == [%{value: "Dudley Square Branch Library"}]
      assert event_payload[:field_start_time] == [%{value: "2006-08-30T14:00:00"}]
      assert event_payload[:field_end_time] == [%{value: "2006-08-30T17:00:00"}]
      assert event_payload[:field_meeting_id] == [%{value: 5550}]
    end

    test "allows the end time to not be provided" do
      event_payload = from_meeting(fixture(@meeting_missing_end_time))

      assert event_payload[:field_end_time] == [%{value: nil}]
    end

    test "raises an error when the start time is not provided" do
      event_payload =
        @meeting
        |> fixture()
        |> Map.put("meettime", "")

      assert_raise RuntimeError, "Please include a start time.", fn ->
        from_meeting(event_payload)
      end
    end
  end
end
