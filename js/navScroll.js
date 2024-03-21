document.addEventListener("scroll", minNav);

function minNav() {
    var img = document.getElementsByClassName("img-fluid")[0];
    
    // Set the desired width of the logo
    var desiredWidth = "100px";
    
    // Set the width of the logo to the desired width
    img.style.width = desiredWidth;
}
