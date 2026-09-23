document.addEventListener("DOMContentLoaded", function () {
  const voteButtons = document.querySelectorAll(".vote-button");

  voteButtons.forEach(function (button) {
    button.addEventListener("click", async function () {
      const eventId = button.dataset.eventId;
      const vote = button.dataset.vote;

      const endpoint =
        vote === "up"
          ? `/events/${eventId}/upvote`
          : `/events/${eventId}/downvote`;

      button.disabled = true;

      try {
        const response = await fetch(endpoint, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json"
          }
        });

        if (response.status === 401) {
          alert("Please sign in before voting.");
          return;
        }

        if (!response.ok) {
          throw new Error("Unable to submit vote.");
        }

        window.location.reload();
      } catch (error) {
        console.error(error);
        alert("Something went wrong. Please try again.");
      } finally {
        button.disabled = false;
      }
    });
  });
});