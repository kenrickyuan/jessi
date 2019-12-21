let n = 3;

const addNewButton = () => {
  console.log(n);
  const question =
    `<div class="form-group">` +
    `<label for='${n}'>Option ${n}</label>` +
    `<input name="choices[]" type="text" id="${n}" class="form-control form-group" autocomplete="off" />` +
    `</div>` +
    `<hr style="border-width: 4px;" class="m-0">`;
  n += 1;
  const formElement = document.getElementById("choices");

  formElement.insertAdjacentHTML("beforeend", question);
};

const initMultipleChoices = () => {
  const addChoiceBtn = document.querySelector(".add-choice-btn");
  console.log(addChoiceBtn);
  if (addChoiceBtn == null) return;
  addChoiceBtn.addEventListener("click", addNewButton);
};

export default initMultipleChoices;
