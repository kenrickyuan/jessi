let g = 2

const addaNewButton = () => {
  const guest = `<div class="form-group">` +
    `<label for='${g}'>Guest</label>` +
    `<input name="guests[]" type="text" id="${g}" class="form-control form-group" autocomplete="off" />` +
    `</div>` +
    `<hr style="border-width: 4px;" class="m-0">`;

  g += 1
  const guestForm = document.getElementById("guests");

  guestForm.insertAdjacentHTML('beforeend', guest);
}

const initMultipleGuests = () => {
  const addGuestBtn = document.querySelector('.add-guest-btn');
  if (addGuestBtn == null) return;
  addGuestBtn.addEventListener('click', addaNewButton);
}

export default initMultipleGuests;
