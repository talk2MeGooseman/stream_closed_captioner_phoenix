export const InitToast = {
  mounted() {
    init()
  }
}

const init = () => {
  const toastEl = document.querySelector('.toast')
  if (toastEl && toastEl.innerText !== '') {
    toastEl.classList.add("mr-4")
    toastEl.classList.remove("hidden")

    setTimeout(() => {
      toastEl.classList.remove("mr-4")
      toastEl.classList.add("hidden")
    }, 3000);
  }
}

init()
