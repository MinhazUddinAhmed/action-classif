function [feat descr] = run_colorDescriptor(Ipath, scale, args, load_feat)
    global FILE_BUFFER_PATH LIB_DIR;

    OS = computer;
    if(strcmp(computer, 'PCWIN'))
        %TODO
        throw(MException('','Windows not implemented'));
    else
        if(strcmp(computer, 'GLNX86'))
            dir = FILE_BUFFER_PATH;
            cmd = ['./' fullfile(LIB_DIR,'colordescriptors','i386-linux-gcc','colorDescriptor') ' --noErrorLog '];
            back = '';
        else
            if(strcmp(computer, 'GLNXA64'))
                dir = FILE_BUFFER_PATH;
                cmd = ['./' fullfile(LIB_DIR,'colordescriptors','x86_64-linux-gcc','colorDescriptor') ' --noErrorLog '];
                back = '';
            else            
                throw(MException('','Unknown OS'));
            end
        end
    end

    if(nargin == 4)
        input_file = fullfile(back,dir,'input');
        args = [sprintf('--loadRegions %s ', input_file) args];
        write_input(input_file, load_feat);
    end
    
    if scale ~= 1
        im = imresize(imread(Ipath), scale);
        [d f ext] = fileparts(Ipath);
        ext = ext(2:end);
        Ipath = fullfile(FILE_BUFFER_PATH, sprintf('imgtmp.%s', ext));
        imwrite(im, Ipath, ext);
    end
    
    output_file = fullfile(back,dir,'output');
    args = sprintf('%s%s --output %s --outputFormat binary %s', back, Ipath, output_file, args);
    cmd = [cmd args];
    [st res] = system(cmd);    
    [feat descr] = read_output(output_file);
end

