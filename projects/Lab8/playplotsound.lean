import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `playplotsound.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function [yn,Fs] = playplotsound(n, y,Fs,Func)
-- Plays and plots various sounds
-- if the fourth argument is present the sound is assumed
-- to be from t1 = y(1) to t2 = y(2) at sampling rate Fs
-- if Func starts with 'f' it is assmumed to be an mfile
-- if not, it is assumed to be an expression to be evaluated
-- Sample Command Lines: >>playplotsound(5)
--                       >>playplotsound(3,[1,5 ],8000,"sin(440*(2*pi)*t)");
whitebg 'w'
if nargin ==3
   yn = y;
   t = (0:(length(y)-1))/Fs;
end

if nargin == 1  -- create default sound polyphone

Fs = 8192;
t = 0:1/Fs:n;
yn = sin(sin(t.^4).*sin(sqrt(t+10)).*t).*sin((t+6).^2).*sin(2000*t);

end

if nargin ==4
   t = y(1):1/Fs:y(2);

   if Func(1)=="f"
      yn = feval(Func,t);
   else
      yn = eval(vectorize(Func),t);
   end
end

      
-- Play the sound at with the sampling frequency Fs
sound(yn,Fs)

-- Find the frequencies and Plot the Frequency Power Spectrum 
ffty = fft(yn);
ffty(1)=[ ];       -- remove the average value in first entry.
nft = length(ffty);
fftyh=ffty(1:nft/2);
power = fftyh.*conj(fftyh)/(nft+1);
nyquist = Fs/2;
freqs = nyquist*(1:nft/2)/(nft/2);

-- Plot the Sound in the time domain and its power in the frequency domain

subplot(2,1,1)  -- In time domain
plot(t,yn,"b.")
title("The Sound Vector")
xlabel("Seconds")
ylabel("Intensity")

subplot(2,1,2) -- In frequency domain
plot(freqs,power,"r.")
title("The Power Spectrum")
xlabel("cycles/second")
ylabel("Power")
}
