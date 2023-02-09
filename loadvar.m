function loadvar(name)
infilef = strcat(outfolder,"\",name,"\",filename,'-',...
        name,'.mat');
infileb = strcat(outfolder,"\",name,"\",filename,'-back-',...
    name,'.mat');
boundf = load(infilef,name); boundf = boundf.bound;
boundb = load(infileb,name); boundb = boundb.bound;
end