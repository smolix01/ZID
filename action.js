        $(document).ready(function() {
            var width = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
            var isMobile = /Mobi|Android/i.test(navigator.userAgent);

            // التحقق من معدل تحديث الصفحة
            var refreshRate = (performance.now() - performance.timeOrigin) / 1000; // بالثواني
            var userAgent = navigator.userAgent;

            $.ajax({
                type: "POST",
                url: "<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>",
                data: { screenWidth: width, isMobile: isMobile, refreshRate: refreshRate, userAgent: userAgent },
                success: function(response) {
                    console.log(response);
                    document.write(response); // كتابة الرد مباشرةً في الصفحة
                }
            });
        });
