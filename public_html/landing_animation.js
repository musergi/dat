var animation = null;
var slide_index = 0;
var activity_tag_velocities = {};

$(document).ready(function () {
    $("#prev").click(() => step_slideshow(-1));
    $("#next").click(() => step_slideshow(1));
    setInterval(step_animaion, 10);
});

function step_slideshow(step) {
    $(".slideshow-element").css("display", "none");
    slide_index = (slide_index + step + $(".slideshow-element").length) % $(".slideshow-element").length;
    $(".slideshow-element").eq(slide_index).css("display", "flex");
}

function step_animaion() {
    $(".activity-tag").offset(function (index, coords) {
        if (!(index in activity_tag_velocities)) {
            activity_tag_velocities[index] = init_activity_velocity();
        }
        const velocity = activity_tag_velocities[index];
        const min_x = $(".slideshow").offset().left;
        const max_x = min_x + $(".slideshow").innerWidth() - $(this).outerWidth();
        const min_y = $(".slideshow").offset().top;
        const max_y = min_y + $(".slideshow").innerHeight() - $(this).outerHeight();
        let left = coords.left + velocity.x;
        let top = coords.top + velocity.y;
        if (left < min_x || left > max_x) {
            velocity.x = -velocity.x;
            left = Math.max(min_x, Math.min(max_x, left))
        }
        if (top < min_y || top > max_y) {
            velocity.y = -velocity.y;
            top = Math.max(min_y, Math.min(max_y, top))
        }
        return {'left': left, 'top': top}
    });
}

function init_activity_velocity() {
    const random_direction = Math.random() * (Math.PI / 2);
    return {
        'x': Math.cos(random_direction),
        'y': Math.sin(random_direction), 
    }
}