//look at the Meditate:Single card for an example of sending a message to this
default
{
    link_message(integer sender, integer num, string str, key id)
    {
        if (num == 5000)
        {
            llSay(0, str);
        }
    }
}
