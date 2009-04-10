/**
  Sets the count of lines if more than 5 or less than 50.
*/
function lines(id, amount) {
//  if ($(id).rows > 0 && $(id).rows <= 50) {
      $(id).rows += amount;
//  }
}

/**
  Toggles extra-wide input fields
**/
function toggleWide(id) {
  if ($(id).style.width == "140%") {
    $(id).style.width = "";
    $(id + "-widebtn").childNodes[1].src = "/images/icons/more_width.png";
    $(id + "-widebtn").title = "More columns";
  } else {
    $(id).style.width = "140%";
    $(id + "-widebtn").childNodes[1].src = "/images/icons/less_width.png";
    $(id + "-widebtn").title = "Fewer columns";
  }
}

function addBugDialog(glsaid) {
  Modalbox.show("/tools/addbug/"+glsaid, {title: "Add bug", width: 600});
}


//document.observe('dom:loaded', function() {
                        
//});