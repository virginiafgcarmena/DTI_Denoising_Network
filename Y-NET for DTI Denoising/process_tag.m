function [type,subject_no,phase,sequence,direction,b_ref,average_no] = process_tag(tag_no)

%Nomenclature for the tag: it's a 9 digit number. From the biggest to the
%smallest:
%First: Type of subject (1 for patients, 2 for healthy)
%Second and third: Subject number
%Fourth: Phase (diastole -1- SS-2 - systole -3)
%Fifth: Sequence (1 if STEAM, 2 if SE)
%Sixth: Direction of Grad. Encoding
%Seventh: B-REF (150 or 450)
%Eighth and ninth: Average number
try 
    switch floor(tag_no/10e7)
        case 1
            type = "patient";
        case 2
            type = "healthy_subject";
    end

    tag_no = tag_no-10e7*floor(tag_no/10e7);
    subject_no = floor(tag_no/10e5);
    tag_no = tag_no-10e5*floor(tag_no/10e5);

    if type== "healthy_subject"
        switch round(tag_no/10e4)
            case 1
                phase = "diastole";
            case 2
                phase = "SS";
            case 3 
                phase = "systole";   
        end
    elseif type== "patient"
        switch round(tag_no/10e4)
            case 1
                phase = "diastole";
            case 2 
                phase = "systole";   
        end
    end
    tag_no = tag_no-10e4*floor(tag_no/10e4);

    switch floor(tag_no/10e3)
        case 1
            sequence = "SE";
        case 2
            sequence = "STEAM";
    end

    tag_no = tag_no-10e3*floor(tag_no/10e3);
    direction = floor(tag_no/10e2);
    tag_no = tag_no-10e2*floor(tag_no/10e2);
    switch floor(tag_no/10e1)
        case 1
            b_ref = 150;
        case 2 
            b_ref = 450;
    end
    tag_no = tag_no-10e1*floor(tag_no/10e1);
    average_no = tag_no;
catch
    error("Inconsistent tag");
end
end