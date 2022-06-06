async function mergeVideo(video, audio) {
    let { createFFmpeg, fetchFile } = FFmpeg;
    let ffmpeg = createFFmpeg();
    await ffmpeg.load();
    ffmpeg.FS('writeFile', 'video.mp4', await fetchFile(video));
    ffmpeg.FS('writeFile', 'audio.mp4', await fetchFile(audio));
    await ffmpeg.run('-i', 'video.mp4', '-i', 'audio.mp4', '-c', 'copy', 'output.mp4');
    let data = await ffmpeg.FS('readFile', 'output.mp4');
    return new Uint8Array(data.buffer);
};


async function setObserver(video) {
    let isPaused = false;

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.intersectionRatio !== 1 && !video.paused) {
                video.pause();
                isPaused = true;
            } else if (isPaused) {
                video.play();
                isPaused = false
            }
        });
    }, {
        threshold: 1
    });
    observer.observe(video)
}

function intToString(num) {
    num = num.toString().replace(/[^0-9.]/g, '');
    if (num < 1000) {
        return num;
    }
    let si = [
        { v: 1E3, s: "k" },
        { v: 1E6, s: "m" },
        { v: 1E9, s: "b" },
        { v: 1E12, s: "t" },
        { v: 1E15, s: "p" },
        { v: 1E18, s: "e" }
    ];
    let index;
    for (index = si.length - 1; index > 0; index--) {
        if (num >= si[index].v) {
            break;
        }
    }
    return (num / si[index].v).toFixed(1).replace(/\.0+$|(\.[0-9]*[1-9])0+$/, "$1") + si[index].s;
}


window.onload = function () {
    /*
    let subs = [
        "funny",
        "dankmemes",
        "videos",
        "gifs"
    ];
    */
    let subs = [
        "dankmemes",
        "funny"
    ];

    let state = {
        page: 25,
        baseUrl: "https://www.reddit.com/r/" + subs.join('+') + ".json",
        currentUrl: "https://www.reddit.com/r/" + subs.join('+') + ".json",
        afterUrl: "",
        beforeUrl: "",
        scroll: 0
    }

    //getLink(state.currentUrl);
    getLink("https://api.pushshift.io/reddit/search/submission/?subreddit=funny&sort=desc&sort_type=score&after=1523588521&before=1523934121&size=1000")
    function getLink(l) {
        fetch(l).
            then(r => r.json()).
            then(d => getData(d)).
            catch(e => console.error('Error: ' + e.message));
    }

    async function createPost(p) {
        console.log(p);
        /*let full_link = p.full_link;
        full_link = full_link.substring(0, full_link.length - 1) + '.json';
        let data = await fetch(full_link).
            then(r => r.json()).
            then(d => d);
        console.log(data)*/
        let unix_timestamp = p.created_utc;
        let date = new Date(unix_timestamp * 1000);
        let day = ("0" + date.getDate()).slice(-2);
        let month = ("0" + (date.getMonth() + 1)).slice(-2);
        let year = date.getFullYear();
        let main = document.querySelector('.app__videos');


        let vid_container = document.createElement('div');
        vid_container.className = 'video';
        let vid_header = document.createElement('div');
        vid_header.className = 'videoHeader';
        vid_header.innerHTML = `
		<span class="material-icons"> arrow_back </span>
		<h3>Reels ${day}/${month}/${year}</h3>
		<span class="material-icons"> camera_alt </span>
		`;

        let vid_footer = document.createElement('div');
        vid_footer.className = 'videoFooter'
        vid_footer.innerHTML = `
	  <div class="videoFooter__text">
		<img class="user__avatar" src="https://www.w3schools.com/howto/img_avatar.png" alt="" />
		<h3>Random_Things </h3>
	  </div>

	  <div class="videoFooter__ticker">
		<!--<span class="material-icons"> music_note </span>-->
		<p>${p.title}</p>
	  </div>
	  <div class="videoFooter__actions">
		<!--<div class="videoFooter__actionsLeft">
		  <span class="material-icons"> favorite </span>
		  <span class="material-icons"> mode_comment </span>
		  <span class="material-icons"> send </span>
		  <span class="material-icons"> more_horiz </span>
		</div>-->
		<div class="videoFooter__actionsRight">
		  <div class="videoFooter__stat">
			<span class="material-icons"> favorite </span>
			<p>${intToString(p.score)}</p>
		  </div>
		  <div class="videoFooter__stat">
			<span class="material-icons"> mode_comment </span>
			<p>${intToString(p.num_comments)}</p>
		  </div>
		</div>
	  </div>`;

        let video = document.createElement('video');

        let source_video = document.createElement('source');
        source_video.type = "video/mp4";

        let audio_tag = document.createElement('audio');
        let source_audio = document.createElement('source');
        source_audio.type = "audio/mp4";

        audio_tag.appendChild(source_audio)

        let mp4 = p.media.reddit_video.fallback_url;
        source_video.src = mp4;
        source_audio.src = mp4.replace(/\/[^\/]*$/g, '/DASH_audio.mp4')
        //video.pause();
        /*
        let mpd = mp4.replace(/\/[^\/]*$/g, '/DASHPlaylist.mpd');
        let res = await fetch(mpd);
        let manifest = await res.text();
        let parsedManifest = mpdParser.parse(manifest, { mpd });
        //console.log()

        if (parsedManifest.mediaGroups.AUDIO.audio)
            source_audio.src = mp4.replace(/\/[^\/]*$/g, '/audio')
        else
            source_audio.src = mp4.replace(/\/[^\/]*$/g, '/DASH_audio.mp4')
*/
        video.onplay = function () { audio_tag.play(); }
        video.onpause = function () { audio_tag.pause(); }

        video.className = 'video__player';
        //video.src = p.media.reddit_video.fallback_url//"sample.mp4"
        video.setAttribute('autoplay', 'autoplay')

        video.setAttribute('controls', 'controls')

        video.appendChild(source_video);
        video.appendChild(audio_tag);
        vid_container.appendChild(vid_header);
        vid_container.appendChild(video);
        vid_container.appendChild(vid_footer);
        main.appendChild(vid_container);

        setObserver(video);
        //observer.observe(video);
        console.log(p);
        /*if (p.distinguished == "moderator")
            return
        p.url = p.url.replace(/\&amp;/g, '&').replace(/\&quest;/g, '?');
        p.thumbnail = p.thumbnail.replace(/\&amp;/g, '&').replace(/\&quest;/g, '?');
        if (p.thumbnail.search(/\.jpg/i) != -1
            || p.thumbnail.search(/\.png/i) != -1
            || p.thumbnail.search(/\.gif/i) != -1) {
            try {
                let main = document.getElementById('main');
                let post = document.createElement('div');
                post.id = p.id;
                post.className = 'post';
                let title = document.createElement('div');
                title.id = 'title';
                title.innerText = p.title.replace(/\&amp;/g, '&').replace(/\&quest;/g, '?');;

                let content = document.createElement('div');
                content.id = 'content';

                let whatslink = document.createElement('a');
                whatslink.classList.add('whastlink');
                whatslink.title = whatslink.alt = "Mandar via Whatsapp";

                let whatsapp = document.createElement('div');
                whatsapp.classList.add('whatsapp');

                let facelink = document.createElement('a');
                facelink.classList.add('facelink');
                facelink.target = "_tab";
                facelink.title = whatslink.alt = "Mandar via Facebook";

                let facebook = document.createElement('div');
                facebook.classList.add('facebook');

                if (p.url.search('.gifv') != -1) {

                    let url = p.url.replace('.gifv', '.mp4');
                    let video = document.createElement('video');
                    let source = document.createElement('source');
                    let videoclass = document.createElement('div');
                    videoclass.classList.add('video');
                    videoclass.title = "Video";
                    source.src = url;
                    whatslink.href = "whatsapp://send?text=" + url;
                    facelink.href = "http://www.facebook.com/sharer.php?u=" + encodeURIComponent(url) + "&t=victorribeiro.com/memes";
                    source.type = "video/mp4";
                    video.preload = "auto";
                    video.loop = true;
                    video.appendChild(source);

                    content.addEventListener("click", e => play(content));
                    content.appendChild(video);
                    content.appendChild(videoclass);

                } else if (p.url.search(/\.webm/i) != -1) {

                    let video = document.createElement('video');
                    let source = document.createElement('source');
                    let videoclass = document.createElement('div');
                    videoclass.classList.add('video');
                    videoclass.title = "Video";
                    source.src = p.url;
                    whatslink.href = "whatsapp://send?text=" + p.url;
                    facelink.href = "http://www.facebook.com/sharer.php?u=" + encodeURIComponent(p.url) + "&t=victorribeiro.com/memes";
                    source.type = "video/webm";
                    video.preload = "auto";
                    video.loop = true;
                    video.appendChild(source);

                    content.addEventListener("click", e => play(content));
                    content.appendChild(video);
                    content.appendChild(videoclass);

                } else if (p.url.search(/\.jpg/i) != -1 || p.url.search(/\.png/i) != -1 || p.url.search(/\.gif/i) != -1) {

                    let img = new Image();
                    img.src = p.url;
                    whatslink.href = "whatsapp://send?text=" + p.url;
                    facelink.href = "http://www.facebook.com/sharer.php?u=" + encodeURIComponent(p.url) + "&t=victorribeiro.com/memes";
                    content.appendChild(img);

                } else if (p.url.search(/youtube\.com\/watch/i) != -1) {
                    https://youtu.be/BskKbs_BHNg"

                    p.url = p.url.replace('watch?v=', 'embed/').replace(/\&./, '');

        let iframe = document.createElement('iframe');
        iframe.width = 420;
        iframe.height = 315;
        iframe.src = p.url;

        whatslink.href = "whatsapp://send?text=" + p.url;
        facelink.href = "http://www.facebook.com/sharer.php?u=" + encodeURIComponent(p.url) + "&t=victorribeiro.com/memes";

        content.appendChild(iframe);
    } else if (p.url.search(/youtu\.be\//i) != -1) {

        let url = p.url.replace('youtu.be/', 'youtube.com/embed/');

        let iframe = document.createElement('iframe');
        iframe.width = 420;
        iframe.height = 315;
        iframe.src = url;

        whatslink.href = "whatsapp://send?text=" + p.url;
        facelink.href = "http://www.facebook.com/sharer.php?u=" + encodeURIComponent(p.url) + "&t=victorribeiro.com/memes";

        content.appendChild(iframe);
    } else if (p.url.search(/gfycat\.com\//i) != -1) {

        let url = p.url.replace('gfycat.com/', 'gfycat.com/ifr/');
        let iframe = document.createElement('iframe');
        iframe.width = 420;
        iframe.height = 315;
        iframe.src = url;
        whatslink.href = "whatsapp://send?text=" + p.url;
        facelink.href = "http://www.facebook.com/sharer.php?u=" + encodeURIComponent(p.url) + "&t=victorribeiro.com/memes";
        content.appendChild(iframe);

    } else {
        let url = p.url.replace(/\&amp;/g, '&').replace(/\&quest;/g, '?');
        let link = document.createElement('a');
        link.href = url;
        whatslink.href = "whatsapp://send?text=" + url;
        facelink.href = "http://www.facebook.com/sharer.php?u=" + encodeURIComponent(url) + "&t=victorribeiro.com/memes";
        link.target = "_tab";

        let linkclass = document.createElement('div');
        linkclass.classList.add('link');
        linkclass.title = "Link";

        let img = new Image();
        if (p.preview.images[0].source.url) {
            img.src = p.preview.images[0].source.url.replace(/\&amp;/g, '&').replace(/\&quest;/g, '?');
        } else {
            img.src = p.thumbnail;
        }

        link.appendChild(img);
        link.appendChild(linkclass);

        content.appendChild(link);
    }

    facelink.appendChild(facebook);
    whatslink.appendChild(whatsapp);

    post.appendChild(title);
    post.appendChild(content);
    post.appendChild(whatslink);
    post.appendChild(facelink);
    main.appendChild(post);
}
            catch (e) {
    console.error(p, e.message);
}
        }*/
    }

    function getData(d) {
        //let main = document.getElementById('main');
        //main.innerHTML = "";
        for (child of d.data) {
            if (child.is_video) {
                createPost(child);
            }
        }
        state.beforeUrl = state.baseUrl + '?count=' + state.page + '&before=' + d.data.before;
        state.afterUrl = state.baseUrl + '?count=' + state.page + '&after=' + d.data.after;
    }

    function play(ele) {
        if (ele.children[0].paused) {
            ele.children[0].play();
            ele.children[1].style.visibility = "hidden";
        } else {
            ele.children[0].pause();
            ele.children[1].style.visibility = "visible";
        }
    }
    /*
        document.getElementById('prev').addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            if (state.page > 25) {
                state.page -= 25;
                state.currentUrl = state.beforeUrl;
                getLink(state.beforeUrl);
                window.scrollTo(0, 0);
            }
        });
	
        document.getElementById('next').addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            state.page += 25;
            state.currentUrl = state.afterUrl;
            getLink(state.afterUrl);
            window.scrollTo(0, 0);
        });
	
        document.getElementById('home').addEventListener('click', function (e) {
            getLink(state.baseUrl)
            window.scrollTo(0, 0);
        });*/

};
