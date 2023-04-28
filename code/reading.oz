functor
import
    Browser
    Open
export
    newThread:ReadThread
define

    %%% Pour ouvrir les fichiers
    class TextFile
        from Open.file Open.text
    end


    %%% funtion reads a file line per line and addds each line at the end of the Tunnel stream
    fun {ReadFile TextFile}
        AtEnd NextLine
    in
        % read the next line and add it to the return value, then make a
        % recursive call to read the next line if there is one
        {TextFile getS(NextLine)}

        % first, check if there are lines to read
        {TextFile atEnd(AtEnd)}
        if AtEnd then
            {TextFile close}
            NextLine|nil
        else
            NextLine|{ReadFile TextFile}
        end
    end

    %%% Thread that reads the files
    fun {ReadThread Files N ThreadNumber I SentenceFolder}
        NewFile
    in
        case Files
        of nil then nil
        [] H|T then
            if (I mod N) == ThreadNumber then
                % initialise the file objcect and read the file
                NewFile = {New TextFile init(name:{Append {Append SentenceFolder "/"} H})}
                % this appends all the lines of the file to the tunnel, each line will be separated
                {ReadFile NewFile}|{ReadThread T N ThreadNumber I+1 SentenceFolder}
            else
                {ReadThread T N ThreadNumber I+1 SentenceFolder}
            end
        end
    end
end