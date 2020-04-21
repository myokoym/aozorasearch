function addBookmark(id) {
  //console.log(id);
  var bookmarks = JSON.parse(localStorage.getItem("bookmarks"));
  //console.log(bookmarks);
  if (!bookmarks) {
    bookmarks = [];
  }
  if (bookmarks.indexOf(id) < 0) {
    bookmarks.push(id);
  }
  localStorage.setItem("bookmarks", JSON.stringify(bookmarks));
}

function removeBookmark(id) {
  console.log(id);
  var bookmarks = JSON.parse(localStorage.getItem("bookmarks"));
  bookmarks.splice(bookmarks.indexOf(id), 1);
  localStorage.setItem("bookmarks", JSON.stringify(bookmarks));
}

function goBookmarks(subUrl) {
  if (!subUrl) {
    subUrl = "";
  }
  var bookmarks = JSON.parse(localStorage.getItem("bookmarks"));
  window.location.href = subUrl + "bookmarks?ids=" + bookmarks.join(",");
}
