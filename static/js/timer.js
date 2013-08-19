
var Timer = function (time) {
    this.time = time;
    this.callbacks_array = new Array;
    this.timerobj = null;
};

Timer.prototype.addListener = function (callback) {
    this.callbacks_array.push( callback );
};

Timer.prototype.start = function () {
    // 一つのTimerオブジェクトのtimeoutは1つしか走らないようにしてある
    if( this.timerobj === null ) {
            var self = this;
            this.timerobj = setTimeout(function() {
                self.callbacks_array.forEach( function (callback) {
                    callback();
                } );
                self.timerobj = null;
            }, this.time);
    }
};

Timer.prototype.stop = function () { window.clearTimeout( this.timerobj ); this.timerobj = null; }

